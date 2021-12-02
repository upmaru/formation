defmodule Formation.Lxd.Alpine.Package do
  use Formation.Clients

  alias Formation.Lxd
  alias Lxd.Instance

  @enforce_keys [:slug]
  defstruct [:slug]

  @type t :: %__MODULE__{
          slug: String.t()
        }

  @ignored_errors [
    ~s(Run "rc-update add s6 default" to automatically start a s6 supervision tree on /run/service at boot time.),
    ""
  ]

  @spec add(%Tesla.Client{}, map) ::
          {:error, nil | binary} | {:ok, any}
  def add(
        %Tesla.Client{} = client,
        %Instance.Setup{package: package} = setup
      ) do
    command = """
    apk update && apk add #{package.slug}
    """

    Lxd.execute_and_log(client, setup.slug, command, ignored_errors: @ignored_errors)
  end

  @spec upgrade(any, map) ::
          {:error, binary} | {:ok, any}
  def upgrade(
        %Tesla.Client{} = client,
        %Instance.Setup{package: package} = setup
      ) do
    command = """
    apk update && apk add --upgrade #{package.slug}
    """

    Lxd.execute_and_log(client, setup.slug, command, ignored_errors: @ignored_error)
  end
end
