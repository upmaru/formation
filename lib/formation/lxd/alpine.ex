defmodule Formation.Lxd.Alpine do
  alias Formation.Lxd.Alpine

  alias Alpine.Repository
  alias Alpine.Postgresql

  defdelegate provision_postgresql(client, options \\ []),
    to: Postgresql,
    as: :provision

  defdelegate add_repository_public_key(client, instance),
    to: Repository,
    as: :add_public_key

  defdelegate verify_repository(client, instance),
    to: Repository,
    as: :verify

  defdelegate append_repository(client, instance),
    to: Repository,
    as: :append

  alias Alpine.Package

  defdelegate add_package(client, instance),
    to: Package,
    as: :add

  defdelegate upgrade_package(client, instance),
    to: Package,
    as: :upgrade
end
