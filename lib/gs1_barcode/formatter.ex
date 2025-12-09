defmodule GS1.Formatter do
  @moduledoc """
  Formatting utilities for transforming GS1 barcode into various
  representations, primarily **HRI (Human Readable Interpretation)**.

  Supports custom layouts for printing labels (e.g., ZPL, HTML, or multi-line displays).
  """

  alias GS1.Barcode2D

  @typedoc """
  Options for formatting HRI.

  * `:include` - list of AI strings (e.g., `["01", "10"]`). If provided, only these AIs
    will be included in the output. Default is `nil` (all present AIs will be included).
  * `:before_ai` - string to prepend to the `(AI)` segment. Useful for ZPL commands (`^FD`)
    or visual delimiters. Default is `""`.
  * `:after_ai` - string to append after the `(AI)` segment but *before* the value.
    Default is `""`.
  * `:joiner` - string used to join the distinct segments. Can be a space, a newline (`\n`),
    or a command delimiter. Default is `""`.
  """
  @type hri_opts ::
          {:include, [String.t()] | nil}
          | {:before_ai, String.t()}
          | {:after_ai, String.t()}
          | {:joiner, String.t()}

  @doc """
  Formats `Barcode2D` struct into a formatted HRI string.
  Options allow for filtering specific fields or generating custom printer commands.

  ## Options

  See `t:hri_opts/0` for details.

  ## Examples

  ### 1. Standard HRI with default opts
      iex> GS1.Formatter.to_hri(barcode)
      "(01)09876543210987(10)BATCH123"

  ### 2. Including specific fields Only)
      iex> GS1.Formatter.to_hri(barcode, include: ["01"])
      "(01)09876543210987"

  ### 3. Visual Spacing
      iex> GS1.Formatter.to_hri(barcode, before_ai: " ", after_ai: ": ")
      " (01): 09876543210987 (10): BATCH123"

  ### 4. ZPL / Printer Format. Generates a ZPL block where each line is a field
      iex> GS1.Formatter.to_hri(barcode,
      ...>   before_ai: "^FO50,50^ADN,36,20^FD", # Start Field command
      ...>   joiner: "^FS\\n"                    # Field Separator + Newline
      ...> )
      "^FO50,50^ADN,36,20^FD(01)09876543210987^FS\\n^FO50,50^ADN,36,20^FD(10)BATCH123"
  """
  @spec to_hri(Barcode2D.t(), [hri_opts()]) :: String.t()
  def to_hri(%Barcode2D{ais: ais}, opts \\ []) do
    include = Keyword.get(opts, :include)
    before_ai = Keyword.get(opts, :before_ai, "")
    after_ai = Keyword.get(opts, :after_ai, "")
    joiner = Keyword.get(opts, :joiner, "")

    ais
    |> Map.to_list()
    |> filter_ais(include)
    |> List.keysort(0)
    |> build_string(before_ai, after_ai, joiner)
  end

  def to_gs1(%Barcode2D{ais: _ais}, _opts \\ []) do
    raise "Not implemented."
  end

  # Private section

  defp filter_ais(ais, nil), do: ais

  defp filter_ais(ais, whitelist) do
    Enum.filter(ais, fn {ai, _val} -> ai in whitelist end)
  end

  defp build_string(ais, before_ai, after_ai, joiner) do
    Enum.map_join(ais, joiner, fn {ai, data} ->
      "#{before_ai}(#{ai})#{after_ai}#{data}"
    end)
  end
end
