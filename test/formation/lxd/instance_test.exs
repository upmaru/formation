defmodule Formation.Lxd.InstanceTest do
  use ExUnit.Case,
    async: true

  import Mox

  setup :verify_on_exit!

  alias Formation.Lxd.{
    Alpine,
    Instance
  }

  alias Alpine.{
    Repository,
    Package
  }

  @uuid "some-operation-id"

  @key_name "key-name"
  @repositories [
    %{
      url: "some-url",
      public_key_name: @key_name,
      public_key: "some-key"
    }
  ]

  setup do
    client = Lexdee.create_client("http://localhost:1234")

    instance =
      Instance.new(%{
        slug: "some-instance-1",
        repositories: @repositories,
        package: %{slug: "some-package-slug"}
      })

    {:ok, client: client, instance: instance}
  end

  describe "new" do
    test "create new instance" do
      assert %Instance{
               repositories: [%Repository{}],
               package: %Package{}
             } =
               Instance.new(%{
                 slug: "some-instance-1",
                 repositories: @repositories,
                 package: %{slug: "some-package-slug"}
               })
    end
  end

  describe "setup" do
    setup do
      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "some-instance-1", command, _options ->
        assert """
               echo 'some-key' > /etc/apk/keys/#{@key_name}.rsa.pub
               """ == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{}}
      end)

      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "some-instance-1", command, _options ->
        assert """
               echo some-url >> /etc/apk/repositories
               """ == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{}}
      end)

      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "some-instance-1", command ->
        assert """
               cat /etc/apk/repositories
               """ == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok,
         %{
           body: %{
             "metadata" => %{
               "output" => %{
                 "1" => "stdout.log",
                 "2" => "stderr.log"
               }
             }
           }
         }}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "some-instance-1", "stdout.log" ->
        {:ok, %{body: "some-url"}}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "some-instance-1", "stderr.log" ->
        {:ok, %{body: ""}}
      end)

      :ok
    end

    test "execute setup command", %{client: client, instance: instance} do
      assert {:ok, :repository_verified} = Instance.setup(client, instance)
    end

    test "execute setup using formation module", %{client: client, instance: instance} do
      assert {:ok, :repository_verified} = Formation.setup_lxd_instance(client, instance)
    end
  end

  describe "add package and restart" do
    setup do
      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "some-instance-1", command ->
        assert """
               apk update && apk add some-package-slug
               """ == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok,
         %{
           body: %{
             "metadata" => %{
               "output" => %{
                 "1" => "stdout.log",
                 "2" => "stderr.log"
               }
             }
           }
         }}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "some-instance-1", "stdout.log" ->
        {:ok, %{body: "some-package-log"}}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "some-instance-1", "stderr.log" ->
        {:ok, %{body: ""}}
      end)

      Formation.LexdeeMock
      |> expect(:restart_instance, fn _client, "some-instance-1" ->
        {:ok, %{body: %{}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{}}
      end)

      :ok
    end

    test "successful execution", %{client: client, instance: instance} do
      assert {:ok, "some-package-log"} = Instance.add_package_and_restart(client, instance)
    end

    test "successful execution with formation module", %{client: client, instance: instance} do
      assert {:ok, "some-package-log"} =
               Formation.add_package_and_restart_lxd_instance(client, instance)
    end
  end
end
