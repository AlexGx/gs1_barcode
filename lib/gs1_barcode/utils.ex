defmodule GS1.Utils do
  @moduledoc false

  alias GS1.Code

  @doc """
  Validates if a code structure matches a GLN (Global Location Number).
  GLN is structurally identical to a GTIN-13 but relies on context.

  ## Example

    GS1.Utils.valid_gln?("4006381333931")
    true
  """
  @spec valid_gln?(String.t()) :: boolean()
  def valid_gln?(code) do
    case Code.detect(code) do
      {:ok, :gtin13} -> true
      _ -> false
    end
  end
end
