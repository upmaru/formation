defmodule Formation do
  @moduledoc """
  Documentation for Formation.
  """
  alias Formation.Lxd

  defdelegate lxd_start(client, slug),
    to: Lxd,
    as: :start

  defdelegate lxd_create(client, slug, params),
    to: Lxd,
    as: :create

  defdelegate lxd_stop(client, slug),
    to: Lxd,
    as: :stop

  defdelegate lxd_delete(client, slug),
    to: Lxd,
    as: :delete

  defdelegate new_lxd_instance(params),
    to: Lxd.Instance,
    as: :new

  defdelegate setup_lxd_instance(client, instance),
    to: Lxd.Instance,
    as: :setup

  defdelegate add_package_and_restart_lxd_instance(client, instance),
    to: Lxd.Instance,
    as: :add_package_and_restart

  defdelegate lxd_upgrade_alpine_package(client, instance),
    to: Lxd.Alpine,
    as: :upgrade_package
end
