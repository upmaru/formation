defmodule Formation.Aws.Bucket.Manager do
  alias Formation.Aws.Bucket

  def create(client, params)

  def create(client, %{name: name, acl: "private" = acl}) do
    client
    |> AWS.S3.create_bucket(name, %{
      "ObjectOwnership" => "BucketOwnerPreferred",
      "CreateBucketConfiguration" => %{
        "LocationConstraint" => client.region
      }
    })
    |> case do
      {:ok, _, _} ->
        {:ok, %Bucket{name: name, acl: acl}}

      error ->
        error
    end
  end

  def create(client, %{name: name, acl: "public" = acl}) do
    with {:ok, _, _} <-
           AWS.S3.create_bucket(client, name, %{
             "ObjectOwnership" => "BucketOwnerPreferred",
             "CreateBucketConfiguration" => %{
               "LocationConstraint" => client.region
             }
           }),
         {:ok, _, _} <-
           AWS.S3.put_public_access_block(client, name, %{
             "PublicAccessBlockConfiguration" => %{
               "BlockPublicAcls" => false,
               "IgnorePublicAcls" => false,
               "BlockPublicPolicy" => true,
               "RestrictPublicBuckets" => true
             }
           }) do
      {:ok, %Bucket{name: name, acl: acl}}
    else
      error -> error
    end
  end

  @tag_mappings %{
    "AllowedHeaders" => "AllowedHeader",
    "AllowedMethods" => "AllowedMethod",
    "AllowedOrigins" => "AllowedOrigin",
    "ExposeHeaders" => "ExposeHeader"
  }

  def update_cors(client, %Bucket{name: name} = bucket, %{cors: cors_parameters})
      when is_list(cors_parameters) do
    patched_cors_params =
      Enum.map(cors_parameters, fn rule ->
        Enum.map(rule, fn {k, v} ->
          if k in Map.keys(@tag_mappings) do
            key = Map.fetch!(@tag_mappings, k)

            {key, v}
          else
            {k, v}
          end
        end)
        |> Enum.into(%{})
      end)

    AWS.S3.put_bucket_cors(client, name, %{
      "CORSConfiguration" => %{
        "CORSRule" => patched_cors_params
      }
    })
    |> case do
      {:ok, _, _} ->
        {:ok, %{bucket | cors: cors_parameters}}

      error ->
        error
    end
  end
end
