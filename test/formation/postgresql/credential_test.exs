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
    test "can create credential with certificate", %{
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
                 certificate: "https://some.cert/file.pem",
                 ssl: false
               })

      refute is_nil(credential.certificate)
    end
  end
end
