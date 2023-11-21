defmodule Formation.Aws.Bucket do
  defstruct [:name, :acl]

  alias Formation.S3.Credential

  def create_credential_and_bucket(%Credential{
    access_key_id: access_key_id, 
    secret_access_key: secret_access_key,
    region: region
  }, options \\ []) do
    permission = Keyword.get(options, :permission, "basic")
    acl = Keyword.get(options, :acl, "private")

    name = if slug = Keyword.get(options, :slug) do
      slug
    else
      Ecto.UUID.generate()
      |> String.split("-")
      |> List.first()
    end

    client = Formation.Aws.client(access_key_id, secret_access_key, region)

    with {:ok, %__MODULE__{} = bucket} <- __MODULE__.Manager.create(client, %{"name" => name, "acl" => acl})
  end
end
