defmodule Formation.Lxd.Alpine.Postgresql do
  alias Formation.Lxd

  def provision(client, options \\ []) do
    project = Keyword.get(options, :project) || "default"
    version = Keyword.get(options, :version, 15)
    hostname = System.get_env("HOSTNAME")

    command = """
    apk add postgresql#{version} postgresql#{version}-jit postgresql#{version}-contrib && rc-update add postgresql && rc-service postgresql start
    """

    Lxd.execute_and_log(client, hostname, command, project: project)
  end

  def connection_url(options \\ []) do
    scheme = Keyword.get(options, :scheme, "postgresql")

    "#{scheme}://postgres:@localhost:5432/postgres"
  end
end
