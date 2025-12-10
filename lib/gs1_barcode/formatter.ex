defmodule GS1.Formatter do
  @moduledoc """
  Formatting utilities for transforming GS1 barcode into various
  representations.

  Supports custom layouts for printing labels (e.g., ZPL, HTML, or multi-line displays).
  """

  alias GS1.AIRegistry
  alias GS1.Consts
  alias GS1.DataStructure

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
  Formats `DataStructure` struct into a formatted HRI string.
  Options allow for filtering specific fields or generating custom printer commands.

  ## Options

  See `t:hri_opts/0` for details.

  ## Examples

  ### 1. Standard HRI with default opts
      iex> GS1.Formatter.to_hri(ds)
      "(01)09876543210987(10)BATCH123"

  ### 2. Including specific fields Only)
      iex> GS1.Formatter.to_hri(ds, include: ["01"])
      "(01)09876543210987"

  ### 3. Visual Spacing
      iex> GS1.Formatter.to_hri(ds, before_ai: " ", after_ai: ": ")
      " (01): 09876543210987 (10): BATCH123"

  ### 4. ZPL / Printer Format. Generates a ZPL block where each line is a field
      iex> GS1.Formatter.to_hri(ds,
      ...>   before_ai: "^FO50,50^ADN,36,20^FD", # Start Field command
      ...>   joiner: "^FS\\n"                    # Field Separator + Newline
      ...> )
      "^FO50,50^ADN,36,20^FD(01)09876543210987^FS\\n^FO50,50^ADN,36,20^FD(10)BATCH123"
  """
  @spec to_hri(DataStructure.t(), [hri_opts()]) :: String.t()
  def to_hri(%DataStructure{ais: ais}, opts \\ []) do
    include = Keyword.get(opts, :include)
    before_ai = Keyword.get(opts, :before_ai, "")
    after_ai = Keyword.get(opts, :after_ai, "")
    joiner = Keyword.get(opts, :joiner, "")

    ais
    |> Map.to_list()
    |> filter_ais(include)
    |> List.keysort(0)
    |> build_hri_string(before_ai, after_ai, joiner)
  end

  @typedoc """
  Options for formatting GS1.

  * `:include` - list of AIs to include. Default `nil` (all).
  * `:prefix` - prefix (e.g., "]d2"). Default is the struct's `fnc1_prefix`.
  * `:group_separator` - character or string used to terminate variable length fields.
    Default is `Consts.gs_symbol()` (`\\x1D`).
  """
  @type gs1_opts ::
          {:include, [String.t()] | nil}
          | {:prefix, String.t()}
          | {:group_separator, String.t()}

  @doc """
  Constructs  GS1 encoded string from the Data Structure.
  Automatically handles the insertion of GS for var-length AIs.

  ## Options

    See `t:gs1_opts/0` for details.

  ## Logic
  1. Prepends the Symbology Identifier (Prefix).
  2. Iterates through AIs.
  3. If an AI is **variable-length** (e.g., AI 10 or 21) AND it is **not** the last element,
     adds the `group_separator`.
  4. Fixed-length AIs (e.g., 01 or 11) do not receive a separator.

  ## Examples
      iex> GS1.Formatter.to_gs1(ds)
      "]d2010987654321098710BATCH123"

      # Variable length field followed by another field gets a separator:
      iex> GS1.Formatter.to_gs1(ds_with_serial)
      "]d2010987654321098710BATCH123\\x1D21SERIAL"
  """
  @spec to_gs1(DataStructure.t(), [gs1_opts()]) :: String.t()
  def to_gs1(%DataStructure{fnc1_prefix: fnc1_prefix, ais: ais}, opts \\ []) do
    include = Keyword.get(opts, :include)
    prefix = Keyword.get(opts, :prefix, fnc1_prefix)
    group_separator = Keyword.get(opts, :group_separator, Consts.gs_symbol())

    encoded =
      ais
      |> Map.to_list()
      |> filter_ais(include)
      |> List.keysort(0)
      |> build_gs1_string(group_separator)

    prefix <> encoded
  end

  # Private section

  defp filter_ais(ais, nil), do: ais

  defp filter_ais(ais, whitelist) do
    Enum.filter(ais, fn {ai, _val} -> ai in whitelist end)
  end

  defp build_hri_string(ais, before_ai, after_ai, joiner) do
    Enum.map_join(ais, joiner, fn {ai, data} ->
      "#{before_ai}(#{ai})#{after_ai}#{data}"
    end)
  end

  defp build_gs1_string([], _sep), do: ""

  # last elem
  defp build_gs1_string([{ai, data}], _sep) do
    ai <> data
  end

  defp build_gs1_string([{ai, data} | rest], sep) do
    # if AI is NOT in the fixed len list, it is var and needs a separator
    suffix = if AIRegistry.fixed_len_ai?(ai), do: "", else: sep
    ai <> data <> suffix <> build_gs1_string(rest, sep)
  end
end
