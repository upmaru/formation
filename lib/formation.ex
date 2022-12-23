defmodule Formation do
  @moduledoc """
  Documentation for Formation.
  """
  alias Formation.Lxd

  defdelegate new_lxd_instance(params),
    to: Lxd.Instance,
    as: :new

  defdelegate setup_lxd_instance(client, instance),
    to: Lxd.Instance,
    as: :setup

  defdelegate add_package_and_restart_lxd_instance(client, instance),
    to: Lxd.Instance,
    as: :add_package_and_restart

  defdelegate lxd_create(client, slug, params),
    to: Lxd,
    as: :create

  defdelegate lxd_start(client, slug),
    to: Lxd,
    as: :start
end
