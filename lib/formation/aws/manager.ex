defmodule Formation.Aws.Manager do
  alias Formation.Aws.Bucket
  alias Formation.S3.Credential

  def create_credential_and_bucket(
        %Credential{
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          region: region
        },
        options \\ []
      ) do
    finch = Keyword.get(options, :finch, AWS.Finch)
    permission = Keyword.get(options, :permission, "basic")
    acl = Keyword.get(options, :acl, "private")

    identifier = 
      if id = Keyword.get(options, :id) do
        id
      else
        Ecto.UUID.generate()
        |> String.split("-")
        |> List.first()
      end

    name = "opsmaru-bucket-#{identifier}"

    client = Formation.Aws.client(access_key_id, secret_access_key, region, finch: finch)

    with {:ok, %Bucket{} = bucket} <-
           Formation.Aws.create_bucket(client, %{name: name, acl: acl}),
         {:ok, %Credential{} = credential} <-
           Formation.Aws.create_credential(client, bucket, %{id: identifier, permission: permission}) do
      {:ok, credential}
    end
  end
end
