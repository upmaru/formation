defmodule Formation.Aws.ManagerTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  alias Formation.S3.Credential

  setup do
    finch_name = TestFinch
    Finch.start_link(name: finch_name)

    {:ok, credential} =
      Credential.create(%{
        type: :component,
        region: "us-west-2",
        access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
        secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")
      })

    {:ok, finch: finch_name, credential: credential}
  end

  test "create_credential_and_bucket/2 creates a private bucket", %{
    credential: credential,
    finch: finch
  } do
    use_cassette "create_credential_and_bucket", match_requests_on: [:request_body] do
      assert {:ok, %Credential{}} =
               Formation.Aws.create_credential_and_bucket(credential, id: "test", finch: finch)
    end
  end

  test "create_credential_and_bucket/2 creates a public bucket", %{
    credential: credential,
    finch: finch
  } do
    use_cassette "create_credential_and_public_bucket", match_requests_on: [:request_body] do
      assert {:ok, %Credential{}} =
               Formation.Aws.create_credential_and_bucket(
                 credential,
                 id: "test-public",
                 acl: "public",
                 finch: finch
               )
    end
  end

  test "create_credential_and_bucket with cors", %{credential: credential, finch: finch} do
    use_cassette "create_credential_and_bucket_with_cors", match_requests_on: [:request_body] do
      assert {:ok, %Credential{cors: cors}} =
               Formation.Aws.create_credential_and_bucket(
                 credential,
                 id: "test-cors",
                 finch: finch,
                 cors: """
                  [
                    {
                      "AllowedHeaders": [
                        "Content-Type",
                        "Content-MD5",
                        "Content-Disposition"
                      ],
                      "AllowedMethods": [
                        "PUT"
                      ],
                      "AllowedOrigins": [
                        "https://some-example.com"
                      ],
                      "MaxAgeSeconds": 3600
                    }
                 ]
                 """
               )

      assert Enum.count(cors) == 1

      [rule] = cors

      assert %{
               "AllowedHeaders" => _,
               "AllowedMethods" => _,
               "AllowedOrigins" => _,
               "MaxAgeSeconds" => _
             } = rule
    end
  end
end
