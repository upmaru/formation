defmodule Formation.PostgresqlTest do
  use ExUnit.Case,
    async: true

  alias Formation.Postgresql
  alias Formation.Postgresql.Credential

  setup do
    host = System.get_env("FORMATION_PG_HOST", "localhost")
    port = System.get_env("FORMATION_PG_PORT", "5432")
    username = System.get_env("FORMATION_PG_USER", "postgres")
    password = System.get_env("FORMATION_PG_PASSWORD", "postgres")

    IO.inspect(host)
    IO.inspect(port)
    IO.inspect(username)
    IO.inspect(password)


    {:ok, host: host, port: port, username: username, password: password}
  end

  describe "create user and database" do
    test "successfully return credential", %{
      host: host,
      port: port,
      username: username,
      password: password
    } do
      assert {:ok, credential} =
               Postgresql.create_user_and_database(host, port, username, password)

      assert %Credential{} = credential
    end
  end
end
