defmodule Formation.Lxd.Instance do
  use Formation.Clients
  
  def create(client, instance_params, node_slug) do
    with {:ok, %{body: operation}} <-
           @lexdee.create_instance(client, instance_params,
             query: [target: node_slug]
           ),
         {:ok, _wait_result} <-
           @lexdee.wait_for_operation(client, operation["id"],
             query: [timeout: 60]
           ) do
      {:ok, client}
    else
      _ -> {:error, :instance_create_failed}
    end
  end
end