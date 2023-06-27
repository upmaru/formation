defmodule Formation.Postgresql.Database do
  def create(pid, name, username) do
    Postgrex.query(pid, "CREATE DATABASE #{name} WITH OWNER #{username}", [])
  end
end
