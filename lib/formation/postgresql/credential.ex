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
    certificate
    ssl
  )a

  @primary_key false
  embedded_schema do
    field :host, :string, virtual: true
    field :resource, :string, virtual: true
    field :secure, :string, virtual: true

    field :port, :integer, default: 5432
    field :hostname, :string
    field :username, :string
    field :password, :string
    field :database, :string, default: "postgres"
    field :ssl, :boolean, default: true

    field :certificate, :string
  end

  def changeset(credential, params) do
    credential
    |> cast(params, @valid_attrs)
    |> maybe_set_hostname()
    |> maybe_set_database()
    |> maybe_set_ssl()
    |> maybe_parse_certificate()
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

  defp maybe_parse_certificate(changeset) do
    if certificate = get_change(changeset, :certificate) do
      put_change(changeset, :certificate, parse_certificate(certificate))
    else
      changeset
    end
  end

  defp maybe_set_ssl(changeset) do
    if secure = get_change(changeset, :secure) do
      put_change(changeset, :ssl, secure)
    else
      changeset
    end
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

  defp parse_certificate(certificate) when is_binary(certificate) do
    with {:ok, uri} <- URI.new(certificate),
         {:ok, %{body: body}} <- Formation.Client.get(to_string(uri)) do
      body
    else
      {:error, _} ->
        certificate
    end
  end
end
