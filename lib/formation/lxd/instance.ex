defmodule Formation.Lxd.Instance do
  @enforce_keys [:slug, :repository, :package]
  defstruct [:slug, :repository, :package]

  alias Formation.Lxd

  alias Lxd.Alpine.{
    Package,
    Repository
  }

  @type t :: %__MODULE__{
          slug: String.t(),
          repository: Repository.t(),
          package: Package.t()
        }

  alias Formation.Lxd.Alpine

  def new(%{
        slug: slug,
        url: url,
        credential: %{"public_key" => public_key},
        package: package
      }) do
    %__MODULE__{
      slug: slug,
      repository: %Repository{
        url: url,
        public_key: public_key
      },
      package: %Package{
        slug: package.slug
      }
    }
  end

  def setup(%Tesla.Client{} = client, %__MODULE__{} = instance) do
    with {:ok, _add_public_key_result} <-
           Alpine.add_repository_public_key(client, instance),
         {:ok, _append_result} <-
           Alpine.append_repository(client, instance),
         {:ok, :repository_verified = output} <-
           Alpine.verify_repository(client, instance) do
      {:ok, output}
    else
      {:error, failed_output} ->
        {:error, failed_output}
    end
  end

  def add_package_and_restart(%Tesla.Client{} = client, %__MODULE__{} = instance) do
    lxd = Lxd.impl()

    with {:ok, add_package_output} <-
           Alpine.add_package(client, instance),
         {:ok, %{body: restart_operation}} <-
           lxd.restart_instance(client, instance.slug),
         {:ok, _restart_result} <-
           lxd.wait_for_operation(client, restart_operation["id"], query: [timeout: 120]) do
      {:ok, add_package_output}
    else
      {:error, %{body: %{"error" => error}}} ->
        {:error, error}

      {:error, failed_output} ->
        {:error, failed_output}
    end
  end
end
