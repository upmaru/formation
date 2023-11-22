defmodule Formation.S3.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_attrs ~w(
    host
    username
    password
    resource
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
    field :host, :string, virtual: true
    field :username, :string, virtual: true
    field :password, :string, virtual: true
    field :resource, :string, virtual: true

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
    |> maybe_set_access_key()
    |> maybe_set_secret_key()
    |> maybe_set_region()
    |> maybe_set_endpoint()
    |> validate_required([:type, :region, :access_key_id, :secret_access_key])
    |> maybe_validate_bucket()
    |> validate_inclusion(:acl, ["private", "public"])
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

  defp maybe_set_access_key(changeset) do
    if username = get_field(changeset, :username) do
      put_change(changeset, :access_key_id, username)
    else
      changeset
    end
  end

  defp maybe_set_secret_key(changeset) do
    if password = get_field(changeset, :password) do
      put_change(changeset, :secret_access_key, password)
    else
      changeset
    end
  end

  defp maybe_set_region(changeset) do
    if resource = get_field(changeset, :resource) do
      put_change(changeset, :region, resource)
    else
      changeset
    end
  end

  defp maybe_set_endpoint(changeset) do
    if host = get_change(changeset, :host) do
      put_change(changeset, :endpoint, host)
    else
      changeset
    end
  end
end
