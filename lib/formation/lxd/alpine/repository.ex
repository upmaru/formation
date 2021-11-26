defmodule Formation.Lxd.Alpine.Repository do
  use Formation.Clients
  
  def append(client, slug, url) do  
    command = """
    echo #{url} >> /etc/apk/repositories
    """
  
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
  
  def add_public_key(client, slug, %{"public_key" => public_key}) do
    command = """
    echo '#{public_key}' > /etc/apk/keys/pakman.rsa.pub
    """
  
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
  
  def verify(client, slug, url) do
    command = """
    cat /etc/apk/repositories
    """
  
    with {:ok, %{body: operation}} <-
           client
           |> @lexdee.execute_command(
             slug,
             command
           ),
         {:ok, %{body: %{"metadata" => %{"output" => %{"1" => stdout}}}}} <-
           client
           |> @lexdee.wait_for_operation(
             operation["id"],
             query: [timeout: 60]
           ),
         {:ok, %{body: log_output}} <-
           client
           |> @lexdee.show_instance_log(
             slug,
             Path.basename(stdout)
           ) do
      if log_output =~ url do
        {:ok, :repository_verified}
      else
        {:error, :repository_verify_failed}
      end
    else
      {:error, error} -> {:error, error}
    end
  end
end