defmodule Formation.Postgresql do
  alias __MODULE__.Client

  defdelegate new_client(host, port, username, password, database \\ "postgres"),
    to: Client,
    as: :new

  alias __MODULE__.User

  defdelegate create_user(pid, username, password),
    to: User,
    as: :create

  defdelegate grant_user_all_permissions(pid, username, database),
    to: User,
    as: :grant_all

  alias __MODULE__.Database

  defdelegate create_database(pid, name, username),
    to: Database,
    as: :create

  alias __MODULE__.Manager

  defdelegate create_user_and_database(host, port, username, password),
    to: Manager

  alias __MODULE__.Credential

  defdelegate credential_to_url(credential),
    to: Credential,
    as: :to_url
end
