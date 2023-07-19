defmodule Formation.Postgresql.Manager do
  alias Formation.Postgresql
  alias Formation.Postgresql.Credential

  def create_user_and_database(%Credential{hostname: host, port: port} = credential) do
    {:ok, pid} =
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

    database =
      uuid
      |> String.split("-")
      |> List.last()

    database = "db_#{database}"

    alias Formation.Postgresql

    with {:ok, %Postgrex.Result{}} <- Postgresql.create_user(pid, new_user, new_password),
         {:ok, %Postgrex.Result{}} <- Postgresql.create_database(pid, database, new_user),
         {:ok, credential} <-
           Credential.create(%{
             hostname: host,
             port: port,
             username: new_user,
             password: new_password,
             database: database
           }) do
      {:ok, credential}
    end
  end
end
