defmodule Formation.Aws.Bucket.Manager do
  alias Formation.Aws.Bucket

  def create(client, params)

  def create(client, %{"name" => name, "acl" => "private" = acl}) do
    AWS.S3.create_bucket(client, name, %{
      "ObjectOwnership" => "BucketOwnerPreferred"
    })
    |> case do
      {:ok, _, _} ->
        {:ok, %Bucket{name: name, acl: acl}}

      error ->
        error
    end
  end

  def create(client, %{"name" => name, "acl" => "public" = acl}) do
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
      {:ok, %Bucket{name: name, variant: variant}}
    else
      error -> error
    end
  end
end