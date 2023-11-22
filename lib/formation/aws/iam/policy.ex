defmodule Formation.Aws.IAM.Policy do
  alias Formation.Aws.Bucket

  def build(id, resource, permission)

  def build(id, %Bucket{name: bucket_name}, "basic") do
    %{
      "Version" => "2012-10-17",
      "Statement" => [
        %{
          "Sid" => id,
          "Effect" => "Allow",
          "Action" => [
            "s3:PutObject",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:DeleteObject",
            "s3:PutObjectAcl"
          ],
          "Resource" => [
            "arn:aws:s3:::#{bucket_name}",
            "arn:aws:s3:::#{bucket_name}/*"
          ]
        }
      ]
    }
  end
end
