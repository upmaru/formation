defmodule Formation.Clients.Lexdee.Behaviour do
  @callback show_instance_log(%Tesla.Client{}, binary, binary) ::
              {:ok, binary} | {:error, any}
  @callback show_instance_log(%Tesla.Client{}, binary, binary, Keyword.t()) ::
              {:ok, binary} | {:error, any}

  @callback execute_command(%Tesla.Client{}, binary, binary) ::
              {:ok, any} | {:error, any}
  @callback execute_command(%Tesla.Client{}, binary, binary, Keyword.t()) ::
              {:ok, any} | {:error, any}
  @callback wait_for_operation(%Tesla.Client{}, map, Keyword.t()) ::
              {:ok, any} | {:error, any}
  @callback create_profile(%Tesla.Client{}, map) :: {:ok, any} | {:error, any}
  @callback update_profile(%Tesla.Client{}, binary, map) :: {:ok, any} | {:error, any}
  @callback create_certificate(%Tesla.Client{}, map) :: {:ok, any} | {:error, any}
  @callback create_instance(%Tesla.Client{}, map, Keyword.t()) ::
              {:ok, map} | {:error, map}

  @callback delete_instance(%Tesla.Client{}, binary) :: {:ok, any} | {:error, any}

  @callback start_instance(%Tesla.Client{}, binary) :: {:ok, any} | {:error, any}
  @callback restart_instance(%Tesla.Client{}, binary) :: {:ok, any} | {:error, any}
  @callback stop_instance(%Tesla.Client{}, binary, keyword) :: {:ok, any} | {:error, any}

  @callback get_cluster_members(%Tesla.Client{}) :: {:ok, list}
  @callback get_cluster_member(%Tesla.Client{}, binary) :: {:ok, map}
end
