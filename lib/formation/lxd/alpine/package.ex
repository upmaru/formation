defmodule Formation.Lxd.Alpine.Package do
  alias Formation.Lxd
  alias Lxd.Instance

  import Formation.Utilities

  @enforce_keys [:slug]
  defstruct [:slug]

  @type t :: %__MODULE__{
          slug: String.t()
        }

  @ignored_errors [
    ~s(Run "rc-update add s6 default" to automatically start a s6 supervision tree on /run/service at boot time.),
    ""
  ]

  def new(%{slug: slug}), do: %__MODULE__{slug: slug}

  def new(params) when is_map(params) do
    params
    |> atomize_keys()
    |> new()
  end

  @spec add(%Tesla.Client{}, map) ::
          {:error, nil | binary} | {:ok, any}
  def add(
        %Tesla.Client{} = client,
        %Instance{slug: slug, package: %__MODULE__{} = package}
      ) do
    command = """
    apk update && apk add #{package.slug}
    """

    Lxd.execute_and_log(client, slug, command, ignored_errors: @ignored_errors)
  end

  @spec upgrade(any, map) ::
          {:error, binary} | {:ok, any}
  def upgrade(
        %Tesla.Client{} = client,
        %Instance{slug: slug, package: %__MODULE__{} = package}
      ) do
    command = """
    apk update && apk add --upgrade #{package.slug}
    """

    Lxd.execute_and_log(client, slug, command, ignored_errors: @ignored_errors)
  end
end
