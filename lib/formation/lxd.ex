defmodule Formation.Lxd do
  @spec start(%Tesla.Client{}, binary, Keyword.t()) :: %Tesla.Client{} | {:error, atom}
  def start(client, slug, options \\ []) do
    project = Keyword.get(options, :project, "default")
    lxd = impl()

    with {:ok, %{body: operation}} <- lxd.start_instance(client, slug, query: [project: project]),
         {:ok, _start_result} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: timeout()]) do
      client
    else
      _ -> {:error, :instance_start_failed}
    end
  end

  @spec create(%Tesla.Client{}, binary, map, Keyword.t()) :: %Tesla.Client{} | {:error, atom}
  def create(%Tesla.Client{} = client, slug, instance_params, options \\ []) do
    project = Keyword.get(options, :project, "default")
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.create_instance(client, instance_params, query: [target: slug, project: project]),
         {:ok, _wait_result} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: timeout()]) do
      client
    else
      _ -> {:error, :instance_create_failed}
    end
  end

  def stop(%Tesla.Client{} = client, slug, options \\ []) do
    project = Keyword.get(options, :project, "default")
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.stop_instance(client, slug, force: true, query: [project: project]),
         {:ok, %{body: %{"err" => "", "status_code" => 200} = body}} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: timeout()]) do
      {:ok, body}
    else
      {:ok, %{body: %{"err" => "The instance is already stopped"}}} ->
        {:ok, %{"err" => "", "status_code" => 200}}

      {:error, %{"error" => "Instance not found"} = error} ->
        {:error, error}

      _ ->
        {:error, :instance_stop_failed}
    end
  end

  def delete(%Tesla.Client{} = client, slug, options \\ []) do
    project = Keyword.get(options, :project, "default")
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.delete_instance(client, slug, query: [project: project]),
         {:ok, %{body: body}} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: timeout()]) do
      {:ok, body}
    else
      _ ->
        {:error, :instance_delete_failed}
    end
  end

  @doc """
  Use execute to execute a command on an instance
  """
  @spec execute(%Tesla.Client{}, binary, binary, Keyword.t()) :: {:ok, map} | {:error, any}
  def execute(client, slug, command, options \\ []) do
    project = Keyword.get(options, :project, "default")
    lxd = impl()

    client
    |> lxd.execute_command(
      slug,
      command,
      settings: %{record_output: false},
      query: [project: project]
    )
    |> case do
      {:ok, %{body: operation}} ->
        client
        |> lxd.wait_for_operation(
          operation["id"],
          query: [timeout: timeout()]
        )

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Execute command and return the log output
  """

  def execute_and_log(client, slug, command, options \\ []) do
    project = Keyword.get(options, :project, "default")
    lxd = impl()

    with {:ok, %{body: operation}} <-
           lxd.execute_command(client, slug, command, query: [project: project]),
         {:ok,
          %{
            body: %{
              "metadata" => %{"output" => %{"1" => stdout, "2" => stderr}}
            }
          }} <-
           lxd.wait_for_operation(client, operation["id"], query: [timeout: timeout()]),
         {:ok, %{body: log_output}} <-
           client
           |> lxd.show_instance_log(
             slug,
             Path.basename(stdout),
             query: [project: project]
           ),
         {:ok, %{body: err_output}} =
           client
           |> lxd.show_instance_log(
             slug,
             Path.basename(stderr),
             query: [project: project]
           ) do
      if process_errors(err_output, Keyword.get(options, :ignored_errors, [""])) == [] do
        {:ok, log_output}
      else
        {:error, err_output}
      end
    else
      {:ok, %{body: %{"error_code" => error_code} = error}} when error_code >= 400 ->
        {:error, error}

      {:ok, %{body: %{"status_code" => status_code} = error}} when status_code >= 400 ->
        {:error, error}

      {:ok, _} ->
        {:error, "failed to retrieve log output"}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec impl :: atom()
  def impl, do: Application.get_env(:formation, :lexdee, Lexdee)

  defp process_errors(nil, _ignored_errors), do: []

  defp process_errors(err_output, ignored_errors) do
    err_output
    |> String.split("\n")
    |> Enum.reject(fn err ->
      String.trim(err) in ignored_errors
    end)
  end

  def timeout do
    Application.get_env(:formation, __MODULE__, [])
    |> Keyword.get(:timeout, 120)
  end
end
