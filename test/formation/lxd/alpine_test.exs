defmodule Formation.Lxd.AlpineTest do
  use ExUnit.Case, async: true

  import Mox

  setup :verify_on_exit!

  alias Formation.Lxd.Alpine

  @uuid "some-operation-id"
  @repositories []

  setup do
    client = Lexdee.create_client("http://localhost:1234")

    instance =
      Formation.new_lxd_instance(%{
        slug: "some-instance-1",
        repositories: @repositories,
        packages: [%{slug: "some-package-slug"}]
      })

    {:ok, client: client, instance: instance}
  end

  describe "upgrade package" do
    setup do
      Formation.LexdeeMock
      |> expect(:execute_command, fn _client, "some-instance-1", command, options ->
        assert [query: [project: "default"]] == options

        assert "apk update && apk add --upgrade some-package-slug\n" == command

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
      |> expect(:show_instance_log, fn _client, "some-instance-1", "stdout.log", options ->
        assert [query: [project: project]] = options

        assert project == "default"

        {:ok, %{body: "some-url"}}
      end)

      Formation.LexdeeMock
      |> expect(:show_instance_log, fn _client, "some-instance-1", "stderr.log", options ->
        assert [query: [project: project]] = options

        assert project == "default"

        {:ok, %{body: ""}}
      end)

      :ok
    end

    test "execute upgrade package", %{client: client, instance: instance} do
      assert {:ok, _result} = Alpine.upgrade_package(client, instance)
    end

    test "execute upgrade package using formation module", %{client: client, instance: instance} do
      assert {:ok, _result} = Formation.lxd_upgrade_alpine_package(client, instance)
    end
  end
end
