defmodule Formation.Aws.Bucket do
  defstruct [:name, :acl, :cors]

  def new(%{"bucket" => bucket, "acl" => acl}) do
    %__MODULE__{
      name: bucket,
      acl: acl
    }
  end

  defdelegate check_difference(operations, operation_name, existing, new),
    to: __MODULE__.Difference,
    as: :check
end
