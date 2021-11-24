defmodule Formation.Alpine.Lxd.Package do
  @ignored_errors [
    ~s(Run "rc-update add s6 default" to automatically start a s6 supervision tree on /run/service at boot time.),
    ""
  ]
  
  defp handle_command(command, client, %{slug: instance_slug}) do
    with {:ok, %{body: operation}} <-
           @lexdee.execute_command(client, instance_slug, command),
         {:ok,
          %{
            body: %{
              "metadata" => %{"output" => %{"1" => stdout, "2" => stderr}}
            }
          }} <-
           @lexdee.wait_for_operation(client, operation["id"],
             query: [timeout: 60]
           ),
         {:ok, %{body: log_output}} <-
           client
           |> @lexdee.show_instance_log(
             instance_slug,
             Path.basename(stdout)
           ),
         {:ok, %{body: err_output}} =
           client
           |> @lexdee.show_instance_log(
             instance_slug,
             Path.basename(stderr)
           ) do
      if process_errors(err_output) == [] do
        {:ok, log_output}
      else
        {:error, err_output}
      end
    else
      {:error, error} -> {:error, error}
    end
  end
  
  defp process_errors(nil), do: []
    
  defp process_errors(err_output) do
    err_output
    |> String.split("\n")
    |> Enum.reject(fn err ->
      err in @ignored_errors
    end)
  end
end