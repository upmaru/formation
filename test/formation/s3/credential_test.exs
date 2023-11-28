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

  describe "accept cors configuration" do
    setup do
      {:ok, credential} =
        Credential.create(%{
          "type" => "component",
          "username" => "someaccesskey",
          "password" => "somesecretkey",
          "host" => "s3.amazonaws.com",
          "resource" => "us-east-1"
        })

      {:ok, credential: credential}
    end

    test "can accept cors configuration", %{credential: credential} do
      assert {:ok, %Credential{} = _credential} =
               Credential.update(credential, %{
                 cors: [
                   %{
                     "AllowedHeaders" => ["*"],
                     "AllowedMethods" => ["GET", "PUT"],
                     "AllowedOrigins" => ["*"],
                     "MaxAgeSeconds" => 3000
                   }
                 ]
               })
    end
  end
end
