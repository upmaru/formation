defmodule Formation.Lxd.Instance do
  use Formation.Clients
    
  def start(%Tesla.Client{} = client, slug) do
      with {:ok, %{body: operation}} <- @lexdee.start_instance(client, slug),
           {:ok, _start_result} <-
             @lexdee.wait_for_operation(client, operation["id"],
               query: [timeout: 60]
             ) do
        client
      else
        _ -> {:error, :instance_start_failed}
      end
    end
  
  def create(%Tesla.Client{} = client, slug, instance_params) do
    with {:ok, %{body: operation}} <-
           @lexdee.create_instance(client, instance_params,
             query: [target: slug]
           ),
         {:ok, _wait_result} <-
           @lexdee.wait_for_operation(client, operation["id"],
             query: [timeout: 60]
           ) do
      client
    else
      _ -> {:error, :instance_create_failed}
    end
  end
  
  alias __MODULE__.Setup
  
  defdelegate setup(client, setup),
    to: Setup,
    as: :perform
end