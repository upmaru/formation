defmodule Formation.Lxd do
  @spec start(%Tesla.Client{}, binary) :: %Tesla.Client{} | {:error, atom}
  def start(client, slug) do
    lxd = impl()

    with {:ok, %{body: operation}} <- lxd.start_instance(client, slug),
         {:ok, _start_result} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: 120]) do
      client
    else
      _ -> {:error, :instance_start_failed}
    end
  end

  @spec create(%Tesla.Client{}, binary, map) :: %Tesla.Client{} | {:error, atom}
  def create(%Tesla.Client{} = client, slug, instance_params) do
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.create_instance(client, instance_params, query: [target: slug]),
         {:ok, _wait_result} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: 120]) do
      client
    else
      _ -> {:error, :instance_create_failed}
    end
  end

  def stop(%Tesla.Client{} = client, slug) do
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.stop_instance(client, slug, force: true),
         {:ok, %{body: %{"err" => "", "status_code" => 200} = body}} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: 120]) do
      {:ok, body}
    else
      {:ok, %{body: %{"err" => "The instance is already stopped"}}} ->
        {:ok, %{"err" => "", "status_code" => 200}}

      _ ->
        {:error, :instance_stop_failed}
    end
  end

  def delete(%Tesla.Client{} = client, slug) do
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.delete_instance(client, slug),
         {:ok, %{body: body}} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: 120]) do
      {:ok, body}
    else
      _ ->
        {:error, :instance_delete_failed}
    end
  end

  @doc """
  Use execute to execute a command on an instance
  """
  @spec execute(%Tesla.Client{}, binary, binary) :: {:ok, map} | {:error, any}
  def execute(client, slug, command) do
    lxd = impl()

    client
    |> lxd.execute_command(
      slug,
      command,
      settings: %{record_output: false}
    )
    |> case do
      {:ok, %{body: operation}} ->
        client
        |> lxd.wait_for_operation(
          operation["id"],
          query: [timeout: 300]
        )

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Execute command and return the log output
  """

  def execute_and_log(client, slug, command, options \\ []) do
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.execute_command(client, slug, command),
         {:ok,
          %{
            body: %{
              "metadata" => %{"output" => %{"1" => stdout, "2" => stderr}}
            }
          }} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: 120]),
         {:ok, %{body: log_output}} <-
           client
           |> lxd.show_instance_log(
             slug,
             Path.basename(stdout)
           ),
         {:ok, %{body: err_output}} =
           client
           |> lxd.show_instance_log(
             slug,
             Path.basename(stderr)
           ) do
      if process_errors(err_output, Keyword.get(options, :ignored_errors, [""])) == [] do
        {:ok, log_output}
      else
        {:error, err_output}
      end
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec impl :: atom()
  def impl, do: Application.get_env(:formation, :lexdee, Lexdee)

  defp process_errors(nil, _ignored_errors), do: []

  defp process_errors(err_output, ignored_errors) do
    err_output
    |> String.split("\n")
    |> Enum.reject(fn err ->
      err in ignored_errors
    end)
  end
end
