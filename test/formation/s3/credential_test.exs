defmodule Formation.S3.CredentialTest do
  use ExUnit.Case, async: true

  alias Formation.S3.Credential

  test "can accept component credential parameters" do
    assert {:ok, %Credential{} = credential} =
             Credential.create(%{
               "type" => "component",
               "username" => "someaccesskey",
               "password" => "somesecretkey",
               "host" => "s3.amazonaws.com",
               "resource" => "us-east-1"
             })

    assert credential.type == :component
    assert credential.access_key_id == "someaccesskey"
    assert credential.region == "us-east-1"
    assert credential.secret_access_key == "somesecretkey"
  end
end
