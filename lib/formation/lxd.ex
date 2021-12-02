defmodule Formation.Lxd do
  use Formation.Clients

  def start(client, slug) do
    with {:ok, %{body: operation}} <- @lexdee.start_instance(client, slug),
         {:ok, _start_result} <-
           @lexdee.wait_for_operation(client, operation["id"], query: [timeout: 60]) do
      client
    else
      _ -> {:error, :instance_start_failed}
    end
  end

  def create(%Tesla.Client{} = client, slug, instance_params) do
    with {:ok, %{body: operation}} <-
           @lexdee.create_instance(client, instance_params, query: [target: slug]),
         {:ok, _wait_result} <-
           @lexdee.wait_for_operation(client, operation["id"], query: [timeout: 60]) do
      client
    else
      _ -> {:error, :instance_create_failed}
    end
  end

  @doc """
  Use execute to execute a command on an instance
  """

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

  @doc """
  Execute command and return the log output
  """

  def execute_and_log(client, slug, command, options \\ []) do
    with {:ok, %{body: operation}} <-
           @lexdee.execute_command(client, slug, command),
         {:ok,
          %{
            body: %{
              "metadata" => %{"output" => %{"1" => stdout, "2" => stderr}}
            }
          }} <-
           @lexdee.wait_for_operation(client, operation["id"], query: [timeout: 60]),
         {:ok, %{body: log_output}} <-
           client
           |> @lexdee.show_instance_log(
             slug,
             Path.basename(stdout)
           ),
         {:ok, %{body: err_output}} =
           client
           |> @lexdee.show_instance_log(
             slug,
             Path.basename(stderr)
           ) do
      if process_errors(err_output, Keyword.get(options, :ignored_errors, [])) == [] do
        {:ok, log_output}
      else
        {:error, err_output}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  defp process_errors(nil, _ignored_errors), do: []

  defp process_errors(err_output, ignored_errors) do
    err_output
    |> String.split("\n")
    |> Enum.reject(fn err ->
      err in ignored_errors
    end)
  end
end
