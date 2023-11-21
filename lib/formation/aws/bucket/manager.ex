defmodule Formation.Aws.Bucket.Manager do
  def create(client, params)

  def create(client, %{"name" => name, "variant" => "private" = variant}) do
    AWS.S3.create_bucket(client, name, %{
      "ObjectOwnership" => "BucketOwnerPreferred"
    })
    |> case do
      {:ok, _, _} ->
        {:ok, %__MODULE__{name: name, variant: variant}}

      error ->
        error
    end
  end

  def create(client, %{"name" => name, "variant" => "public" = variant}) do
    with {:ok, _, _} <-
           AWS.S3.create_bucket(client, name, %{
             "ObjectOwnership" => "BucketOwnerPreferred"
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
      {:ok, %__MODULE__{name: name, variant: variant}}
    else
      error -> error
    end
  end
end