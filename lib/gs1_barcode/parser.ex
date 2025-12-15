defmodule GS1.Parser do
  @moduledoc """
  Parser for GS1 Data Structures.

  Parsing pipeline:
  1. **Prefix matching**: Identifies the Symbology Identifier (e.g., `]d2` for DataMatrix).
  2. **Tokenization**: Splits the raw string into segments using `Tokenizer`. Each segment is defined
  by 2 digit "base AI" (than must be normalized and checked and verified with `AIRegistry`) and data part.
  3. **Normalization**: Reconstructs full AIs from tokens (e.g., merging `31` + `03` -> `3103`)
     and performs compliance checks against the `AIRegistry`.
  4. **Date Structure creation**: Returns `t:GS1.DataStructure.t/0` suitable for further validation and processing.
  """

  alias GS1.AIRegistry
  alias GS1.DataStructure
  alias GS1.FNC1Prefix
  alias GS1.Tokenizer

  @base_ai_len 2

  @typedoc """
  Error reasons returned by `parse/1`.

  ## Simple errors

    * `:empty` - input string is empty.
    * `:invalid_input` - input is not a binary string.

  ## Tokenization errors

    * `{:tokenize, reason, position}` - string structure is invalid or malformed.
      The `reason` is a description from the tokenizer, and `position` is
      character index where the invalid sequence begins.

  ## AI processing errors

  All AI errors include a tuple `{ai, data}` containing the AI code
  and its associated data segment:

    * `{:unknown_ai, {ai, data}}` - AI is not recognized in the registry.
    * `{:duplicate_ai, {ai, data}}` - same AI appears more than once.
    * `{:not_enough_data, {ai, data}}` - data segment is too short to
      reconstruct a 3 or 4 digit AI.
    * `{:ai_part_non_num, {ai, data}}` - expected numeric digits for the AI
      suffix during reconstruction, but found non-digit characters.
  """
  @type error_reason ::
          :empty
          | :invalid_input
          | {:tokenize, String.t(), non_neg_integer()}
          | {:duplicate_ai, {String.t(), String.t()}}
          | {:unknown_ai, {String.t(), String.t()}}
          | {:not_enough_data, {String.t(), String.t()}}
          | {:ai_part_non_num, {String.t(), String.t()}}

  @doc """
  Parses a raw GS1 string into a `GS1.DataStructure`.

  ## Errors

    The following error tuples may be returned:

    * `:empty` - input string is empty.
    * `:invalid_input` - input is not a binary string.
    * `{:tokenize, reason, invalid_seq_start}` - string structure is invalid or malformed.
        An `invalid_seq_start` is an index of bad sequence in input string.
    * `{:unknown_ai, {ai, data}}` - AI is not recognized
    * `{:duplicate_ai, {ai, data}}` - same AI appears twice
    * `{:not_enough_data, {ai, data}}` - string ends prematurely for a AI.
    * `{:ai_part_non_num, {ai, data}}` - expected digits for an AI suffix during reconstruction,
        but found other characters.

  ## Examples

      iex> GS1.Parser.parse("]d20198765432109876")
      {:ok,
        %GS1.DataStructure{
          content: "]d20198765432109876",
          type: :gs1_datamatrix,
          fnc1_prefix: "]d2",
          ais: %{"01" => "98765432109876"}
        }}
  """
  @spec parse(String.t()) :: {:ok, DataStructure.t()} | {:error, error_reason()}

  def parse(<<>>), do: {:error, :empty}

  def parse(input) when is_binary(input) do
    {type, prefix_seq, rest} = FNC1Prefix.match(input)

    case Tokenizer.tokenize(rest) do
      {:ok, tokens, _rest, _context, _line, _byte_offset} ->
        case normalize(tokens) do
          {:error, _} = error ->
            error

          {_seen, ais} ->
            {:ok, DataStructure.new(input, type, prefix_seq, ais)}
        end

      {:error, reason, _rest, _context, {_line, _line_offset}, byte_offset} ->
        <<prefix::binary-size(byte_offset + byte_size(prefix_seq)), _::binary>> = input
        invalid_seq_start = String.length(prefix)
        {:error, {:tokenize, reason, invalid_seq_start}}
    end
  end

  def parse(_), do: {:error, :invalid_input}

  # Private section

  defp normalize(tokens) do
    Enum.reduce_while(tokens, {MapSet.new(), []}, fn {_tag, {raw_ai, raw_data}}, {seen, acc} ->
      do_normalize(raw_ai, raw_data, seen, acc)
    end)
  end

  defp do_normalize(raw_ai, raw_data, seen, acc) do
    case normalize_ai(raw_ai, raw_data) do
      {:ok, {ai, data}} ->
        if MapSet.member?(seen, ai) do
          {:halt, {:error, {:duplicate_ai, {ai, data}}}}
        else
          {:cont, {MapSet.put(seen, ai), [{ai, data} | acc]}}
        end

      {:error, reason} ->
        {:halt, {:error, reason}}
    end
  end

  defp normalize_ai(ai, data) do
    case AIRegistry.length_by_base_ai(ai) do
      @base_ai_len ->
        {:ok, {ai, data}}

      nil ->
        {:error, {:unknown_ai, {ai, data}}}

      # reconstruct and check 3 and 4 digit AIs
      len when len in [3, 4] ->
        reconstruct_and_verify(ai, data, len)

      # should never happen if AIRegistry is correct and up to date
      _ ->
        {:error, {:unknown_ai, {ai, data}}}
    end
  end

  defp reconstruct_and_verify(ai, data, len) do
    with {:ok, {full_ai, remaining_data}} <- reconstruct_ai(ai, data, len) do
      if AIRegistry.compliant?(full_ai) do
        {:ok, {full_ai, remaining_data}}
      else
        {:error, {:unknown_ai, {full_ai, remaining_data}}}
      end
    end
  end

  defp reconstruct_ai(ai, data, len) when len == 3 or len == 4 do
    take = len - @base_ai_len

    if String.length(data) <= take do
      {:error, {:not_enough_data, {ai, data}}}
    else
      {taken, rest} = String.split_at(data, take)

      # check if the taken part is numeric, otherwise it's invalid format
      if String.match?(taken, ~r/^\d+$/) do
        {:ok, {ai <> taken, rest}}
      else
        {:error, {:ai_part_non_num, {ai, data}}}
      end
    end
  end

  # must never raise
  defp reconstruct_ai(_ai, _data, _len), do: raise(ArgumentError, "reconstruct_ai/3 invalid len")
end
