defmodule Formation.Lxd do
  use Formation.Clients
  
  def execute(client, slug, command) do
    client
    |> @lexdee.execute_command(
      slug,
      command,
      settings: %{record_output: false}
    )
    |> case do
      {:ok, %{body: operation}} ->
        client
        |> @lexdee.wait_for_operation(
          operation["id"],
          query: [timeout: 60]
        )
    
      {:error, error} ->
        {:error, error}
    end
  end
end
