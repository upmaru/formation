defmodule Formation.LxdTest do
  use ExUnit.Case,
    async: true

  import Mox

  setup :verify_on_exit!

  @uuid "some-operation-id"
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
      |> expect(:start_instance, fn _client, "example-test-1" ->
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
end
