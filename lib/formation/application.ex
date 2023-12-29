defmodule Formation.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Finch, name: AWS.Finch},
      {Finch, name: Formation.Finch}
    ]

    opts = [strategy: :one_for_one, name: Formation.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
