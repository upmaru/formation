defmodule Formation.Postgresql.Client do
  def new(host, port, username, password, database \\ "postgres") do
    Postgrex.start_link(
      hostname: host,
      port: port,
      username: username,
      password: password,
      database: database
    )
  end
end
