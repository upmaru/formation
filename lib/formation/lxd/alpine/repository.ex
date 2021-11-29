defmodule Formation.Lxd.Alpine.Repository do
  use Formation.Clients
  
  alias Formation.Lxd
  alias Lxd.Instance
  
  def append(%Tesla.Client{} = client, %Instance.Setup{} = setup) do  
    command = """
    echo #{setup.url} >> /etc/apk/repositories
    """
  
    Lxd.execute(client, setup.slug, command)
  end
  
  def add_public_key(%Tesla.Client{} = client, %Instance.Setup{} = setup) do
    command = """
    echo '#{setup.public_key}' > /etc/apk/keys/pakman.rsa.pub
    """
  
    Lxd.execute(client, setup.slug, command)
  end
  
  def verify(%Tesla.Client{} = client, %Instance.Setup{} = setup) do
    command = """
    cat /etc/apk/repositories
    """
  
    with {:ok, %{body: operation}} <-
           client
           |> @lexdee.execute_command(
             setup.slug,
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
             setup.slug,
             Path.basename(stdout)
           ) do
      if log_output =~ setup.url do
        {:ok, :repository_verified}
      else
        {:error, :repository_verify_failed}
      end
    else
      {:error, error} -> {:error, error}
    end
  end
end