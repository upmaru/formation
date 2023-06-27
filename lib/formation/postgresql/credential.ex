defmodule Formation.Postgresql.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :host, :string
    field :port, :integer
    field :username, :string
    field :password, :string
    field :database, :string
  end

  def changeset(credential, params) do
    credential
    |> cast(params, [:host, :port, :username, :password, :database])
    |> validate_required([:host, :port, :username])
  end

  def create(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  def to_url(%__MODULE__{} = credential) do
    %URI{
      scheme: "postgresql",
      host: credential.host,
      port: credential.port,
      path: "/#{credential.database}",
      userinfo: "#{credential.username}:#{credential.password}"
    }
    |> to_string()
  end
end
