defmodule Formation.Client do
  use Tesla

  adapter(Tesla.Adapter.Finch, name: Formation.Finch)
end
