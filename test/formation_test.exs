defmodule FormationTest do
  use ExUnit.Case

  @key_name "key-name"
  @repositories [
    %{
      url: "some-url",
      public_key_name: @key_name,
      public_key: "some-key"
    }
  ]

  @repositories_string_keys [
    %{
      "url" => "some-url",
      "public_key_name" => @key_name,
      "public_key" => "some-key"
    }
  ]

  describe "new_lxd_instance" do
    alias Formation.Lxd.Instance

    test "successfully build new instance" do
      assert %Instance{} =
               Formation.new_lxd_instance(%{
                 slug: "some-instance-1",
                 repositories: @repositories,
                 package: %{slug: "some-package-slug"}
               })
    end

    test "new instance string keys" do
      assert %Instance{} =
               Formation.new_lxd_instance(%{
                 "slug" => "some-instance-1",
                 "repositories" => @repositories,
                 "package" => %{slug: "some-package-slug"}
               })

      assert %Instance{} =
               Formation.new_lxd_instance(%{
                 "slug" => "some-instance-1",
                 "repositories" => @repositories,
                 "package" => %{"slug" => "some-package-slug"}
               })

      assert %Instance{} =
               Formation.new_lxd_instance(%{
                 "slug" => "some-instance-1",
                 "repositories" => @repositories_string_keys,
                 "package" => %{"slug" => "some-package-slug"}
               })
    end
  end
end
