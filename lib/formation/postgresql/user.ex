defmodule Formation.Postgresql.User do
  def create(pid, username, password) do
    Postgrex.query(pid, "CREATE USER #{username} WITH ENCRYPTED PASSWORD '#{password}'", [])
  end

  def grant_role(pid, new_user, master_user) do
    Postgrex.query(pid, "GRANT #{new_user} TO #{master_user}", [])
  end

  def grant_all(pid, username, database) do
    Postgrex.query(pid, "GRANT ALL PRIVILEGES ON DATABASE '#{database}' TO #{username}", [])
  end
end
