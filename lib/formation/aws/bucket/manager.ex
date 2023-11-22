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
end
