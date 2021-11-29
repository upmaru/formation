defmodule Formation.Lxd.Alpine do
  alias Formation.Lxd.Alpine
  
  
  alias Alpine.Repository
  
  defdelegate add_repository_public_key(client, slug, credential),
    to: Repository,
    as: :add_public_key
    
  defdelegate verify_repository(client, slug, url),
    to: Repository,
    as: :verify
    
  defdelegate append_repository(client, slug, url),
    to: Repository,
    as: :append
    
  alias Alpine.Package
  
  defdelegate add_package(client, params),
    to: Package,
    as: :add
    
  defdelegate upgrade_package(client, params),
    to: Package,
    as: :upgrade
end
