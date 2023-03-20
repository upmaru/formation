defmodule Formation.Lxd.Alpine.Postgresql do
  alias Formation.Lxd

  def provision(client, options \\ []) do
    version = Keyword.get(options, :version, 15)
    hostname = System.get_env("HOSTNAME")

    command = """
    apk add postgresql#{version} postgresql#{version}-jit && rc-update add postgresql && rc-service postgresql start
    """

    Lxd.execute_and_log(client, hostname, command)
  end

  def default_connection_url(options) do
    scheme = Keyword.get(options, :scheme)

    "#{scheme}://postgres:@localhost:5432/postgres"
  end
end
