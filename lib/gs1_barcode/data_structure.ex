defmodule GS1.DataStructure do
  @moduledoc """
  Decoded GS1 Data Structure, encapsulating AIs, type, prefix, and the original input.
  """

  @type barcode_type ::
          :gs1_datamatrix
          | :gs1_qrcode
          | :gs1_ean
          | :gs1_128
          | :unknown

  @typedoc """
  * `content`: input exactly as received, including prefix if exists.
  * `type`: barcode type (e.g., `:gs1_datamatrix`).
  * `ais`: A map of AI code (string) => data (string).
  * `fnc1_prefix`: The FNC1 prefix string (e.g., `"]d2"`), or `""` if none was found.
  """
  @type t :: %__MODULE__{
          content: String.t(),
          type: barcode_type(),
          ais: %{String.t() => String.t()},
          fnc1_prefix: String.t()
        }

  defstruct content: "",
            type: :unknown,
            fnc1_prefix: <<>>,
            ais: %{}

  @doc """
  Creates a new Barcode struct.

  The `ais` parameter is normalized to a map if a keyword list is provided.
  """
  @spec new(String.t(), barcode_type(), String.t(), map() | keyword()) :: t()
  def new(content, type, fnc1_prefix, ais)
      when is_binary(content) and is_atom(type) do
    %__MODULE__{
      content: content,
      type: type,
      fnc1_prefix: fnc1_prefix,
      ais: Map.new(ais)
    }
  end

  # accessors

  @doc "Returns the raw input of barcode."
  @spec content(t()) :: String.t()
  def content(%__MODULE__{content: content}), do: content

  @doc "Returns type of the barcode."
  @spec type(t()) :: barcode_type()
  def type(%__MODULE__{type: type}), do: type

  @doc "Returns the map of AI codes and their data values."
  @spec ais(t()) :: %{String.t() => String.t()}
  def ais(%__MODULE__{ais: ais}), do: ais

  @doc "Returns the FNC1 prefix binary (<<>> if none was found)."
  @spec fnc1_prefix(t()) :: String.t()
  def fnc1_prefix(%__MODULE__{fnc1_prefix: prefix}), do: prefix

  @doc """
  Checks if a specific Application Identifier (AI) code is present in the decoded data.
  """
  @spec has_ai?(t(), String.t()) :: boolean()
  def has_ai?(%__MODULE__{ais: ais}, code), do: Map.has_key?(ais, code)

  @doc """
  Retrieves the data value associated with a specific AI.
  Returns `nil` if the AI is not present.
  """
  @spec ai(t(), String.t()) :: String.t() | nil
  def ai(%__MODULE__{ais: ais}, code), do: Map.get(ais, code)

  @doc "Returns barcode without FNC1 prefix."
  @spec payload(t()) :: String.t()
  def payload(%__MODULE__{content: content, fnc1_prefix: ""}) do
    content
  end

  def payload(%__MODULE__{content: content, fnc1_prefix: prefix})
      when is_binary(prefix) do
    String.replace_prefix(content, prefix, "")
  end
end
