defmodule Formation.Postgresql.Manager do
  alias Formation.Postgresql
  alias Formation.Postgresql.Credential

  def create_user_and_database(
        %Credential{hostname: host, port: port, username: username} = credential, _options \\ []
      ) do
    {:ok, conn} =
      credential
      |> Map.from_struct()
      |> Keyword.new()
      |> Postgrex.start_link()

    uuid = Ecto.UUID.generate()

    new_user =
      uuid
      |> String.split("-")
      |> List.first()

    new_user = "user_#{new_user}"

    new_password =
      :crypto.strong_rand_bytes(12)
      |> Base.url_encode64()

    new_database =
      uuid
      |> String.split("-")
      |> List.last()

    new_database = "db_#{new_database}"

    with {:ok, %Postgrex.Result{}} <- Postgresql.create_user(conn, new_user, new_password),
         {:ok, %Postgrex.Result{}} <- Postgresql.grant_role_to_user(conn, new_user, username),
         {:ok, %Postgrex.Result{}} <- Postgresql.create_database(conn, new_database, new_user),
         {:ok, new_db_conn} <-
           %{credential | database: new_database}
           |> Map.from_struct()
           |> Keyword.new()
           |> Postgrex.start_link(),
         {:ok, %Postgrex.Result{}} <- Postgresql.grant_public_schema(new_db_conn, new_user),
         {:ok, credential} <-
           Credential.create(%{
             hostname: host,
             port: port,
             username: new_user,
             password: new_password,
             database: new_database
           }) do
      GenServer.stop(conn)
      GenServer.stop(new_db_conn)

      {:ok, credential}
    end
  end
end
