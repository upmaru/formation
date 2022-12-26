defmodule Formation.Lxd.Instance do
  @enforce_keys [:slug, :repositories, :package]
  defstruct [:slug, :repositories, :package]

  import Formation.Utilities

  alias Formation.Lxd

  alias Lxd.Alpine.{
    Package,
    Repository
  }

  @type t :: %__MODULE__{
          slug: String.t(),
          repositories: list(Repository.t()),
          package: Package.t()
        }

  alias Formation.Lxd.Alpine

  def new(%{
        slug: slug,
        repositories: repositories,
        package: package
      }) do
    %__MODULE__{
      slug: slug,
      repositories: Enum.map(repositories, &Repository.new/1),
      package: Package.new(package)
    }
  end

  def new(params) when is_map(params) do
    params
    |> atomize_keys()
    |> new()
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
           lxd.wait_for_operation(client, restart_operation["id"], query: [timeout: Lxd.timeout()]) do
      {:ok, add_package_output}
    else
      {:error, %{body: %{"error" => error}}} ->
        {:error, error}

      {:error, failed_output} ->
        {:error, failed_output}
    end
  end
end
