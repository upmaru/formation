defmodule Formation.Postgresql.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_attrs ~w(
    host
    resource
    port
    hostname
    username
    password
    database
    ssl
  )a

  @primary_key false
  embedded_schema do
    field :host, :string, virtual: true
    field :resource, :string, virtual: true

    field :port, :integer, default: 5432
    field :hostname, :string
    field :username, :string
    field :password, :string
    field :database, :string, default: "postgres"
    field :ssl, :boolean, default: true
  end

  def changeset(credential, params) do
    credential
    |> cast(params, @valid_attrs)
    |> maybe_set_hostname()
    |> maybe_set_database()
    |> validate_required([:hostname, :port, :username, :database])
  end

  def create(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  def to_url(%__MODULE__{} = credential) do
    %URI{
      scheme: "postgresql",
      host: credential.hostname,
      port: credential.port,
      path: "/#{credential.database}",
      userinfo: "#{credential.username}:#{credential.password}"
    }
    |> to_string()
  end

  defp maybe_set_database(changeset) do
    if resource = get_change(changeset, :resource) do
      put_change(changeset, :database, resource)
    else
      changeset
    end
  end

  defp maybe_set_hostname(changeset) do
    if host = get_change(changeset, :host) do
      put_change(changeset, :hostname, host)
    else
      changeset
    end
  end
end
