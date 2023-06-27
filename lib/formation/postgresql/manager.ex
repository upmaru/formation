defmodule Formation.Postgresql.Manager do
  alias Formation.Postgresql

  def create_user_and_database(host, port, username, password) do
    {:ok, pid} = Postgresql.new_client(host, port, username, password)
    uuid = Ecto.UUID.generate()

    new_user =
      uuid
      |> String.split("-")
      |> List.first()

    new_user = "user_#{new_user}"

    new_password =
      :crypto.strong_rand_bytes(12)
      |> Base.url_encode64()

    database =
      uuid
      |> String.split("-")
      |> List.last()

    database = "db_#{database}"

    alias Formation.Postgresql

    with {:ok, %Postgrex.Result{}} <- Postgresql.create_user(pid, new_user, new_password),
         {:ok, %Postgrex.Result{}} <- Postgresql.create_database(pid, database, new_user),
         {:ok, credential} <-
           Postgresql.Credential.create(%{
             host: host,
             port: port,
             username: new_user,
             password: new_password,
             database: database
           }) do
      {:ok, credential}
    end
  end
end
