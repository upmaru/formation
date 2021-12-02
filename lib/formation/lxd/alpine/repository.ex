defmodule Formation.Lxd.Alpine.Repository do
  use Formation.Clients

  alias Formation.Lxd
  alias Lxd.Instance

  @enforce_keys [:url, :public_key]
  defstruct [:url, :public_key]

  @type t :: %__MODULE__{
          url: String.t(),
          public_key: String.t()
        }

  def append(%Tesla.Client{} = client, %Instance{slug: slug, repository: repository}) do
    command = """
    echo #{repository.url} >> /etc/apk/repositories
    """

    Lxd.execute(client, slug, command)
  end

  def add_public_key(%Tesla.Client{} = client, %Instance{slug: slug, repository: repository}) do
    command = """
    echo '#{repository.public_key}' > /etc/apk/keys/pakman.rsa.pub
    """

    Lxd.execute(client, slug, command)
  end

  def verify(%Tesla.Client{} = client, %Instance{slug: slug, repository: repository}) do
    command = """
    cat /etc/apk/repositories
    """

    client
    |> Lxd.execute_and_log(slug, command)
    |> case do
      {:ok, log_output} ->
        if log_output =~ repository.url do
          {:ok, :repository_verified}
        else
          {:error, :repository_verify_failed}
        end

      error ->
        error
    end
  end
end
