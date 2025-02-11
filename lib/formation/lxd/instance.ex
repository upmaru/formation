defmodule Formation.Lxd.Instance do
  @enforce_keys [:project, :slug, :repositories, :packages]
  defstruct [:project, :slug, :repositories, :packages]

  import Formation.Utilities

  alias Formation.Lxd

  alias Lxd.Alpine.{
    Package,
    Repository
  }

  @type t :: %__MODULE__{
          project: String.t(),
          slug: String.t(),
          repositories: list(Repository.t()),
          packages: list(Package.t())
        }

  alias Formation.Lxd.Alpine

  def new(
        %{
          slug: slug,
          repositories: repositories,
          packages: packages
        } = params
      ) do
    %__MODULE__{
      project: Map.get(params, :project) || "default",
      slug: slug,
      repositories: Enum.map(repositories, &Repository.new/1),
      packages: Enum.map(packages, &Package.new/1)
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

  def add_package_and_restart(%Tesla.Client{} = client, %__MODULE__{project: project} = instance) do
    lxd = Lxd.impl()

    with {:ok, add_package_output} <-
           Alpine.add_package(client, instance),
         {:ok, %{body: restart_operation}} <-
           lxd.restart_instance(client, instance.slug, query: [project: project]),
         {:ok, _restart_result} <-
           lxd.wait_for_operation(client, restart_operation["id"],
             query: [timeout: Lxd.timeout()]
           ) do
      {:ok, add_package_output}
    else
      {:error, %{body: %{"error" => error}}} ->
        {:error, error}

      {:error, failed_output} ->
        {:error, failed_output}
    end
  end
end
