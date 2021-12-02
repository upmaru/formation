defmodule Formation.Lxd.Instance do
  use Formation.Clients

  @enforce_keys [:slug, :url, :public_key, :package]
  defstruct [:slug, :url, :public_key, :package]

  alias Formation.Lxd.Alpine.Package

  @type t :: %__MODULE__{
          slug: String.t(),
          url: String.t(),
          public_key: String.t(),
          package: Package.t()
        }

  use Formation.Clients
  alias Formation.Lxd.Alpine

  def new(%{
        slug: slug,
        url: url,
        credential: %{"public_key" => public_key},
        package: package
      }) do
    %__MODULE__{
      slug: slug,
      url: url,
      public_key: public_key,
      package: %Package{slug: package.slug}
    }
  end

  def setup(%Tesla.Client{} = client, %__MODULE__{} = instance) do
    with {:ok, _add_public_key_result} <-
           Alpine.add_repository_public_key(client, instance),
         {:ok, _append_result} <-
           Alpine.append_repository(client, instance),
         {:ok, :repository_verified} <-
           Alpine.verify_repository(client, instance),
         {:ok, add_package_output} <- Alpine.add_package(client, instance),
         {:ok, %{body: restart_operation}} <-
           @lexdee.restart_instance(client, instance.slug),
         {:ok, _restart_result} <-
           @lexdee.wait_for_operation(client, restart_operation["id"], query: [timeout: 60]) do
      {:ok, add_package_output}
    else
      {:error, %{body: %{"error" => error}}} ->
        {:error, error}

      {:error, failed_output} ->
        {:error, failed_output}
    end
  end
end
