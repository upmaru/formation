defmodule Formation.Postgresql.CredentialTest do
  use ExUnit.Case, async: true

  alias Formation.Postgresql.Credential

  setup do
    host = System.get_env("FORMATION_PG_HOST", "localhost")
    port = System.get_env("FORMATION_PG_PORT", "5432")
    username = System.get_env("FORMATION_PG_USER", "postgres")
    password = System.get_env("FORMATION_PG_PASSWORD", "postgres")

    {:ok, host: host, port: port, username: username, password: password}
  end

  describe "create credential with certificate" do
    setup do
      Tesla.Mock.mock(fn %{method: :get} ->
        %Tesla.Env{status: 200, body: "hello"}
      end)

      :ok
    end

    test "can create credential with url certificate", %{
      host: host,
      port: port,
      username: username,
      password: password
    } do
      assert {:ok, credential} =
               Credential.create(%{
                 host: host,
                 port: port,
                 username: username,
                 password: password,
                 certificate:
                   "https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem",
                 ssl: false
               })

      refute is_nil(credential.certificate)

      assert credential.certificate == "hello"
    end

    test "can create credential with binary certificate", %{
      host: host,
      port: port,
      username: username,
      password: password
    } do
      assert {:ok, credential} =
               Credential.create(%{
                 host: host,
                 port: port,
                 username: username,
                 password: password,
                 certificate: "hello",
                 ssl: false
               })

      refute is_nil(credential.certificate)

      assert credential.certificate == "hello"
    end
  end
end
