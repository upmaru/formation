defmodule Formation.Postgresql.ManagerTest do
  use ExUnit.Case, async: true

  alias Formation.Postgresql.Credential
  alias Formation.Postgresql.Manager

  setup do
    host = System.get_env("FORMATION_PG_HOST", "localhost")
    port = System.get_env("FORMATION_PG_PORT", "5432")
    username = System.get_env("FORMATION_PG_USER", "postgres")
    password = System.get_env("FORMATION_PG_PASSWORD", "postgres")

    {:ok, host: host, port: port, username: username, password: password}
  end

  describe "correctly builds connection option" do
    setup %{
      host: host,
      port: port,
      username: username,
      password: password
    } do
      example_cert_pem = File.read!("test/fixture/us-east-1-bundle.pem")

      Tesla.Mock.mock(fn %{method: :get} ->
        %Tesla.Env{status: 200, body: example_cert_pem}
      end)

      {:ok, credential} =
        Credential.create(%{
          host: host,
          port: port,
          username: username,
          password: password,
          certificate: "https://truststore.pki.rds.amazonaws.com/us-east-1/us-east-1-bundle.pem",
          ssl: true
        })

      {:ok, credential: credential}
    end

    test "with ssl enabled", %{
      credential: credential
    } do
      assert [{:ssl_opts, ssl_opts} | _] = Manager.build_connection_options(credential)

      assert is_list(Keyword.get(ssl_opts, :cacerts))
      assert :verify_peer == Keyword.get(ssl_opts, :verify)
    end
  end
end
