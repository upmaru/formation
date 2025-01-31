defmodule Formation.Postgresql.Manager do
  alias Formation.Postgresql
  alias Formation.Postgresql.Credential

  def create_user_and_database(
        %Credential{hostname: host, port: port, username: username} = credential,
        _options \\ []
      ) do
    connection_options = build_connection_options(credential)

    {:ok, conn} = Postgrex.start_link(connection_options)

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
           |> build_connection_options()
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

  def build_connection_options(%Credential{ssl: true, certificate: certificate} = credential)
      when is_binary(certificate) do
    credential_options =
      credential
      |> Map.from_struct()
      |> Keyword.new()

    credential_options
    |> Keyword.put(:ssl_opts,
      verify: :verify_peer,
      cacerts:
        credential.certificate
        |> :public_key.pem_decode()
        |> Enum.map(fn {_, der, _} -> der end),
      server_name_indication: to_charlist(credential.hostname),
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    )
  end

  def build_connection_options(%Credential{} = credential) do
    credential
    |> Map.from_struct()
    |> Keyword.new()
  end
end
