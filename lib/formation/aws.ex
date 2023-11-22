defmodule Formation.Aws do
  alias __MODULE__.Bucket

  defdelegate create_bucket(client, params),
    to: Bucket.Manager,
    as: :create

  alias __MODULE__.IAM

  defdelegate create_credential(client, bucket, params),
    to: IAM.Manager,
    as: :create

  defdelegate create_credential_and_bucket(credential, options),
    to: __MODULE__.Manager

  def client(access_key_id, secret_access_key, region, options \\ []) do
    finch_name = Keyword.get(options, :finch, AWS.Finch)

    access_key_id
    |> AWS.Client.create(secret_access_key, region)
    |> AWS.Client.put_http_client({AWS.HTTPClient.Finch, [finch_name: finch_name]})
  end
end
