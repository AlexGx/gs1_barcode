defmodule GS1.FNC1Prefix do
  @moduledoc """
  GS1 prefix (Symbology Identifier) utils.
  """

  alias GS1.Consts
  alias GS1.DataStructure

  @fnc1_prefixes [
    {:gs1_datamatrix, Consts.fnc1_gs1_datamatrix_seq()},
    {:gs1_qrcode, Consts.fnc1_gs1_qrcode_seq()},
    {:gs1_ean, Consts.fnc1_gs1_ean_seq()},
    {:gs1_128, Consts.fnc1_gs1_128_seq()}
  ]

  @doc """
  Attempts to match the lead of barcode against to GS1 FNC1 sequences.

  ## Examples

      iex> GS1.FNC1Prefix.match("]d20104600494694202")
      {:gs1_datamatrix, "]d2", "0104600494694202"}

      iex> GS1.FNC1Prefix.match("0104600494694202")
      {:unknown, "", "0104600494694202"}
  """
  @spec match(binary()) :: {DataStructure.barcode_type(), binary(), binary()}
  def match(bin), do: do_match(bin)

  # Private section

  for {type, seq} <- @fnc1_prefixes do
    defp do_match(<<unquote(seq), rest::binary>>) do
      {unquote(type), unquote(seq), rest}
    end
  end

  defp do_match(bin), do: {:unknown, <<>>, bin}
end
