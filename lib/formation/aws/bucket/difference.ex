defmodule Formation.Aws.Bucket.Difference do
  def check(operations, operation_name, existing, new)
      when is_binary(new) and is_list(operations) do
    with {:ok, new} <- Jason.decode(new),
         true <- :erlang.phash2(existing) != :erlang.phash2(new) do
      Enum.concat(operations, [%{operation_name => new}])
    else
      _ -> operations
    end
  end
end
