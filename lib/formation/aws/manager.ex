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
    cors = Keyword.get(options, :cors)

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
           Formation.Aws.create_credential(client, bucket, %{
             id: identifier,
             permission: permission
           }) do
      handle_update(client, bucket, %{cors: cors}, {:ok, credential})
    end
  end

  def update_credential_and_bucket(
        %Credential{
          access_key_id: access_key_id,
          secret_access_key: secret_access_key,
          region: region
        },
        %{"credential" => existing_instance_credential},
        options \\ []
      ) do
    finch = Keyword.get(options, :finch, AWS.Finch)
    cors = Keyword.get(options, :cors)
    bucket = Bucket.new(existing_instance_credential)

    client = Formation.Aws.client(access_key_id, secret_access_key, region, finch: finch)

    with {:ok, existing_instance_credential} = existing_credential <-
           Credential.create(existing_instance_credential) do
      []
      |> Bucket.check_difference(:cors, existing_instance_credential.cors, cors)
      |> Enum.reduce(existing_credential, &handle_update(client, bucket, &1, &2))
    end
  end

  defp handle_update(client, bucket, %{cors: cors_params}, {:ok, credential})
       when is_list(cors_params) do
    with {:ok, bucket} <- Formation.Aws.update_bucket_cors(client, bucket, %{cors: cors_params}) do
      Credential.update(credential, %{cors: bucket.cors})
    end
  end

  defp handle_update(client, bucket, %{cors: cors_params}, {:ok, credential})
       when is_binary(cors_params) do
    with {:ok, cors_params} <- Jason.decode(cors_params),
         {:ok, bucket} <-
           Formation.Aws.update_bucket_cors(client, bucket, %{cors: cors_params}) do
      Credential.update(credential, %{cors: bucket.cors})
    end
  end

  defp handle_update(_client, _bucket, _params, {:ok, credential}), do: {:ok, credential}
end
