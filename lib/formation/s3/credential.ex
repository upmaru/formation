defmodule Formation.S3.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_attrs ~w(
    acl
    type
    region
    bucket
    endpoint
    access_key_id
    secret_access_key
  )a

  @primary_key false
  embedded_schema do
    field :type, Ecto.Enum, values: [:component, :instance]

    field :endpoint, :string, default: "s3.amazonaws.com"
    field :bucket, :string
    field :region, :string
    field :access_key_id, :string
    field :secret_access_key, :string
    field :acl, :string, default: "private"
  end

  def changeset(credential, params) do
    credential
    |> cast(params, @valid_attrs)
    |> validate_required([:type, :region, :access_key_id, :secret_access_key])
    |> validate_inclusion(:acl, ["private", "public"])
    |> maybe_validate_bucket()
  end

  def create(params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  defp maybe_validate_bucket(changeset) do
    if fetch_field!(changeset, :type) == :instance do
      validate_required(changeset, [:bucket])
    else
      changeset
    end
  end
end
