defmodule Formation.LxdTest do
  use ExUnit.Case,
    async: true

  import Mox

  setup :verify_on_exit!

  @uuid "some-operation-id"
  @slug "some-instance-1"
  @instance_params %{
    "name" => "example-test-1",
    "profiles" => ["default", "example-1"],
    "source" => %{
      "type" => "image",
      "mode" => "pull",
      "protocol" => "slipstreams",
      "server" => "https://images.linuxcontainers.org",
      "alias" => "alpine/3.14"
    }
  }

  setup do
    client = Lexdee.create_client("http://localhost:1234")

    {:ok, client: client}
  end

  describe "create" do
    alias Formation.Lxd

    test "call create instance and return client", %{client: client} do
      Formation.LexdeeMock
      |> expect(:create_instance, fn _client, params, _options ->
        assert params == @instance_params

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, uuid, _options ->
        assert uuid == @uuid

        {:ok, %{}}
      end)

      assert client == Lxd.create(client, "example-test-1", @instance_params)
    end
  end

  describe "start" do
    alias Formation.Lxd

    test "call start instance and return client", %{client: client} do
      Formation.LexdeeMock
      |> expect(:start_instance, fn _client, "example-test-1", _options ->
        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, uuid, _options ->
        assert uuid == @uuid

        {:ok, %{}}
      end)

      assert client == Lxd.start(client, "example-test-1")
    end
  end

  describe "execute" do
    alias Formation.Lxd

    test "execute a given command", %{client: client} do
      cmd = """
      cat /var/lib/something
      """

      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "example-test-1", command, _options ->
        assert cmd == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{}}
      end)

      assert {:ok, %{}} == Lxd.execute(client, "example-test-1", cmd)
    end
  end

  describe "execute_and_log" do
    alias Formation.Lxd

    test "call with error", %{client: client} do
      cmd = """
      cat /var/lib/something
      """

      error_text = "Failed to retrieve PID of executing child process"

      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "example-test-1", command, _options ->
        assert cmd == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok,
         %{
           body: %{
             "status_code" => 400,
             "err" => error_text
           }
         }}
      end)

      assert {:error, error} = Lxd.execute_and_log(client, "example-test-1", cmd)
      assert %{"err" => ^error_text} = error
    end

    test "ignored error", %{client: client} do
      cmd = """
      cat /var/lib/something
      """

      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "example-test-1", command, _options ->
        assert cmd == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok,
         %{
           body: %{
             "status_code" => 200,
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
      |> expect(:show_instance_log, fn _client, "example-test-1", "stdout.log", options ->
        assert [query: [project: project]] = options

        assert project == "default"

        {:ok, %{body: "some-url"}}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "example-test-1", "stderr.log", options ->
        assert [query: [project: project]] = options

        assert project == "default"

        {:ok, %{body: " * WARNING: some-package is already stopped"}}
      end)

      assert {:ok, "some-url"} =
               Lxd.execute_and_log(client, "example-test-1", cmd,
                 ignored_errors: ["* WARNING: some-package is already stopped"]
               )
    end

    test "error not ignored", %{client: client} do
      cmd = """
      cat /var/lib/something
      """

      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "example-test-1", command, _options ->
        assert cmd == command

        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok,
         %{
           body: %{
             "status_code" => 200,
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
      |> expect(:show_instance_log, fn _client, "example-test-1", "stdout.log", options ->
        assert [query: [project: project]] = options

        assert project == "default"

        {:ok, %{body: "some-url"}}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "example-test-1", "stderr.log", options ->
        assert [query: [project: project]] = options

        assert project == "default"

        {:ok, %{body: "Some error happened"}}
      end)

      assert {:error, "Some error happened"} =
               Lxd.execute_and_log(client, "example-test-1", cmd,
                 ignored_errors: ["* WARNING: some-package is already stopped"]
               )
    end
  end

  describe "stop" do
    alias Formation.Lxd

    test "execute stop instance", %{client: client} do
      Formation.LexdeeMock
      |> expect(:stop_instance, fn _client, "some-instance-1", _options ->
        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{body: %{"err" => "", "status_code" => 200}}}
      end)

      assert {:ok, %{"err" => "", "status_code" => 200}} = Lxd.stop(client, @slug)
    end
  end

  describe "delete" do
    alias Formation.Lxd

    test "execute delete instance", %{client: client} do
      Formation.LexdeeMock
      |> expect(:delete_instance, fn _client, _slug, _options ->
        {:ok, %{body: %{"id" => @uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{body: %{}}}
      end)

      assert {:ok, %{}} = Lxd.delete(client, @slug)
    end
  end
end
