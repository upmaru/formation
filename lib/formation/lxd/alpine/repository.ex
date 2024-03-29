defmodule Formation.Lxd.Alpine.Repository do
  alias Formation.Lxd
  alias Lxd.Instance

  import Formation.Utilities

  @enforce_keys [:url, :public_key_name, :public_key]
  defstruct [:url, :public_key_name, :public_key]

  @type t :: %__MODULE__{
          url: String.t(),
          public_key_name: String.t(),
          public_key: String.t()
        }

  def new(%{
        url: url,
        public_key_name: key_name,
        public_key: public_key
      }) do
    %__MODULE__{
      url: url,
      public_key_name: key_name,
      public_key: public_key
    }
  end

  def new(params) when is_map(params) do
    params
    |> atomize_keys()
    |> new()
  end

  def append(%Tesla.Client{} = client, %Instance{
        slug: slug,
        repositories: repositories,
        project: project
      }) do
    urls =
      repositories
      |> Enum.map(fn repository -> repository.url end)
      |> Enum.join("\n")

    command = """
    echo -e '#{urls}' >> /etc/apk/repositories
    """

    Lxd.execute(client, slug, command, project: project)
  end

  def add_public_key(%Tesla.Client{} = client, %Instance{
        slug: slug,
        repositories: repositories,
        project: project
      }) do
    {:ok,
     Enum.map(repositories, fn repository ->
       command = """
       echo '#{repository.public_key}' > /etc/apk/keys/#{repository.public_key_name}.rsa.pub
       """

       Lxd.execute(client, slug, command, project: project)
     end)}
  end

  def verify(%Tesla.Client{} = client, %Instance{
        slug: slug,
        repositories: repositories,
        project: project
      }) do
    command = """
    cat /etc/apk/repositories
    """

    urls =
      repositories
      |> Enum.map(fn repository -> repository.url end)
      |> Enum.join("\n")

    client
    |> Lxd.execute_and_log(slug, command, project: project)
    |> case do
      {:ok, log_output} ->
        if log_output =~ urls do
          {:ok, :repository_verified}
        else
          {:error, :repository_verify_failed}
        end

      error ->
        error
    end
  end
end
