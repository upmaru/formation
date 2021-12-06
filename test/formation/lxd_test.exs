defmodule Formation.LxdTest do
  use ExUnit.Case,
    async: true

  import Mox

  setup :verify_on_exit!

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

  describe "create" do
    alias Formation.Lxd

    setup do
      client = Lexdee.create_client("http://localhost:1234")

      {:ok, client: client}
    end

    test "call create instance and wait", %{client: client} do
      uuid = "some-operation-id"

      Formation.LexdeeMock
      |> expect(:create_instance, fn _client, _params, _options ->
        {:ok, %{body: %{"id" => uuid}}}
      end)

      Formation.LexdeeMock
      |> expect(:wait_for_operation, fn _client, _uuid, _options ->
        {:ok, %{}}
      end)

      assert client == Lxd.create(client, "example-test-1", @instance_params)
    end
  end
end
