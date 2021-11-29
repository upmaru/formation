defmodule Formation.Lxd.Instance.Setup do
  @enforce_keys [:slug, :url, :public_key]
  defstruct [:slug, :url, :public_key]
  
  @type t :: %__MODULE__{
    slug: String.t,
    url: String.t,
    public_key: String.t
  }
  
  use Formation.Clients
  alias Formation.Lxd.Alpine
  
  def new(%{slug: slug, url: url, credential: %{"public_key" => public_key}}) do
    %__MODULE__{
      slug: slug,
      url: url,
      public_key: public_key
    }
  end
  
  def perform(%Tesla.Client{} = client, %__MODULE__{} = setup) do
    with {:ok, _add_public_key_result} <-
           Alpine.add_repository_public_key(client, setup),
         {:ok, _append_result} <-
           Alpine.append_repository(client, setup),
         {:ok, :repository_verified} <-
           Alpine.verify_repository(client, setup),
         {:ok, add_package_output} <- Alpine.add_package(client, setup),
         {:ok, %{body: restart_operation}} <-
           @lexdee.restart_instance(client, setup),
         {:ok, _restart_result} <-
           @lexdee.wait_for_operation(client, restart_operation["id"],
             query: [timeout: 60]
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