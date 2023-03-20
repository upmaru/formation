defmodule Formation.Lxd.Alpine.PostgresqlTest do
  use ExUnit.Case, async: true

  alias Formation.Lxd.Alpine

  import Mox

  setup do
    client = Lexdee.create_client("http://localhost:1234")
    hostname = System.get_env("HOSTNAME")

    {:ok, client: client, hostname: hostname}
  end

  test "add postgresql", %{client: client, hostname: hostname} do
    Formation.LexdeeMock
    |> expect(:execute_command, fn _client, host, command ->
      assert "apk add postgresql15 postgresql15-jit && rc-update add postgresql && rc-service postgresql start\n" ==
               command

      assert hostname == host

      {:ok, %{body: %{"id" => "some-operation-id"}}}
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
    |> expect(:show_instance_log, fn _client, instance, "stdout.log" ->
      assert hostname == instance

      {:ok, %{body: "some-url"}}
    end)

    Formation.LexdeeMock
    |> expect(:show_instance_log, fn _client, instance, "stderr.log" ->
      assert hostname == instance

      {:ok, %{body: ""}}
    end)

    assert {:ok, _result} = Alpine.provision_postgresql(client)
  end

  test "generate connection url" do
    assert "ecto://postgres:@localhost:5432/postgres" ==
             Alpine.postgresql_connection_url(scheme: "ecto")
  end
end
