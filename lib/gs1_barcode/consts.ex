defmodule GS1.Consts do
  @moduledoc """
  GS1 const values.
  """

  # control characters

  @doc "ASCII Group Separator (ASCII 29, <GS>)"
  @spec gs_symbol :: String.t()
  def gs_symbol, do: "\u001D"

  # barcode type sequences

  @spec fnc1_gs1_datamatrix_seq :: String.t()
  def fnc1_gs1_datamatrix_seq, do: "]d2"

  @spec fnc1_gs1_qrcode_seq :: String.t()
  def fnc1_gs1_qrcode_seq, do: "]Q3"

  @spec fnc1_gs1_ean_seq :: String.t()
  def fnc1_gs1_ean_seq, do: "]e0"

  @spec fnc1_gs1_128_seq :: String.t()
  def fnc1_gs1_128_seq, do: "]C1"
end
