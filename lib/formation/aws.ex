defmodule Formation.Aws do
  defdelegate create_bucket(client, params)
    to: Aws.Bucket.Manager,
    as: :create

  def client(access_key_id, secret_access_key, region) do
    access_key_id
    |> AWS.Client.create(secret_access_key, region)
    |> AWS.Client.put_http_client({AWS.HTTPClient.Finch, [finch_name: AWS.Finch]})
  end
end
