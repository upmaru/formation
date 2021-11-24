defmodule Formation.Clients do
  defmacro __using__(_) do
    quote do
      alias Formation.Clients

      @lexdee Application.get_env(:instellar, :lexdee) || Lexdee
    end
  end
end
