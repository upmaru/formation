defmodule Formation.Aws.IAM.Manager do
  alias Formation.Aws.Bucket
  alias Formation.Aws.IAM
  alias Formation.S3.Credential

  def create(client, resource, params)

  def create(client, %Bucket{} = bucket, %{
        id: id,
        permission: "basic" = permission
      }) do
    policy_document = IAM.Policy.build(id, bucket, permission)

    user_name = "opsmaru-user-#{id}"

    create_user_params = %{
      "Path" => "/",
      "UserName" => user_name,
      "Tags" => %{
        "member" => [
          %{"Key" => "component", "Value" => id}
        ]
      }
    }

    with {:ok, _user_response, _} <- AWS.IAM.create_user(client, create_user_params),
         {:ok, %{"CreatePolicyResponse" => create_policy_response}, _} <-
           AWS.IAM.create_policy(client, %{
             "PolicyName" => "opsmaru-policy-#{id}",
             "PolicyDocument" => Jason.encode!(policy_document)
           }),
         {:ok, _attach_policy_response, _} <-
           AWS.IAM.attach_user_policy(client, %{
             "UserName" => user_name,
             "PolicyArn" => create_policy_response["CreatePolicyResult"]["Policy"]["Arn"]
           }),
         {:ok, access_key_response, _} <-
           AWS.IAM.create_access_key(client, %{"UserName" => user_name}) do
      Credential.create(%{
        type: :instance,
        endpoint: "s3.#{client.region}.amazonaws.com",
        bucket: bucket.name,
        region: client.region,
        access_key_id:
          access_key_response["CreateAccessKeyResponse"]["CreateAccessKeyResult"]["AccessKey"][
            "AccessKeyId"
          ],
        secret_access_key:
          access_key_response["CreateAccessKeyResponse"]["CreateAccessKeyResult"]["AccessKey"][
            "SecretAccessKey"
          ]
      })
    end
  end
end
