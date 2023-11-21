defmodule Formation.Aws.Bucket.IAM.Manager do
  alias Formation.Aws.Bucket

  def create(client, bucket, params)

  def create(client, %Bucket{} = bucket, %{
    "instllation_slug" => slug,
    "permission" => "basic"
  }) do
    sid =
      slug
      |> String.replace("-", "_")
      |> Macro.camelize()

    policy_document = %{
      "Version" => "2012-10-17",
      "Statement" => [
        %{
          "Sid" => sid,
          "Effect" => "Allow",
          "Action" => [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:PutObjectAcl"
          ],
          "Resource" => [
            "arn:aws:s3:::#{bucket.name}",
            "arn:aws:s3:::#{bucket.name}/*"
          ]
        }
      ]
    }

    create_user_params = %{
      "Path" => "/",
      "UserName" => slug,
      "Tags" => %{
        "member" => [
          %{"Key" => "installation", "Value" => slug}
        ]
      }
    }

    create_policy_params = %{
      "PolicyName" => "#{slug}-policy",
      "PolicyDocument" => Jason.encode!(policy_document)
    }

    with {:ok, user_response, _} <- AWS.IAM.create_user(client, create_user_params),
         {:ok, policy_response, _} <- AWS.IAM.create_policy_name(client, create_policy_params),
         {:ok, attach_policy_response, _} <-
           AWS.IAM.attach_user_policy(client, %{
             "UserName" => slug,
             "PolicyArn" =>
               policy_response["CreatePolicyResponse"]["CreatePolicyResult"]["Policy"]["Arn"]
           }),
         {:ok, access_key_response, _} <- AWS.IAM.create_access_key(client, %{"UserName" => slug}) do

    end
  end
end