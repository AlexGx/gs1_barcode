defmodule GS1.Consts do
  @moduledoc """
  GS1 const values used in GS1 barcode processing.
  """

  # Control characters

  @doc "ASCII Group Separator (ASCII 29, <GS>)"
  @spec gs_symbol :: String.t()
  def gs_symbol, do: "\u001D"

  # Barcode type sequences

  @doc "Symbology Identifier for a GS1 DataMatrix."
  @spec fnc1_gs1_datamatrix_seq :: String.t()
  def fnc1_gs1_datamatrix_seq, do: "]d2"

  @doc "Symbology Identifier for a GS1 QR Code."
  @spec fnc1_gs1_qrcode_seq :: String.t()
  def fnc1_gs1_qrcode_seq, do: "]Q3"

  @doc "Symbology Identifier for GS1 DataBar."
  @spec fnc1_gs1_ean_seq :: String.t()
  def fnc1_gs1_ean_seq, do: "]e0"

  @doc "Symbology Identifier for GS1-128 (Code 128)."
  @spec fnc1_gs1_128_seq :: String.t()
  def fnc1_gs1_128_seq, do: "]C1"
end
