defmodule Formation.Utilities do
  def atomize_keys(params) do
    params
    |> Enum.map(fn {key, value} ->
      {String.to_existing_atom(key), value}
    end)
    |> Enum.into(%{})
  end
end
