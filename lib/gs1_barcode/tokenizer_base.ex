defmodule GS1.Tokenizer.Base do
  @moduledoc """
  Compile–time base for GS1 tokenizers based on NimbleParsec.
  The tokenizer is deliberately “dumb”: it does not perform GS1-specific semantic checks or validations.

  The tokenizer **always returns AI prefixes in their minimal, two-digit form**,
  even when the actual GS1 AI is longer.

  All tokens produced by the tokenizer **must undergo further normalization**
  to reconstruct the canonical AI and produce Element Strings.
  """

  @typedoc """
  The type of the Application Identifier (AI).
  * `:ai_fixed` - The AI has a fixed length.
  * `:ai_var` - The AI has a variable length (delimited by FNC1/GS or end of string).
  """
  @type token_kind :: :ai_fixed | :ai_var

  @typedoc """
  The raw data tuple extracted by the tokenizer.
  Format: `{ai_prefix, data_content}`.
  """
  @type token_data :: {String.t(), String.t()}

  @typedoc "A single parsed token. Wraps the kind and the data tuple."
  @type token :: {token_kind(), token_data()}

  @typedoc """
  The result returned by `tokenize/2`.
  Includes the list of tokens, remaining binary, context, line, and offset.
  """
  @type tokenize_result ::
          {:ok, [token()], rest :: binary(), context :: map(), line :: pos_integer(),
           byte_offset :: pos_integer()}
          | {:error, reason :: String.t(), rest :: binary(), context :: map(),
             line :: pos_integer(), byte_offset :: pos_integer()}

  defmacro __using__(opts \\ []) do
    {evaluated_opts, _bindings} = Code.eval_quoted(opts, [], __CALLER__)

    fixed_ais = Keyword.fetch!(evaluated_opts, :fixed_ais)

    gs_symbol =
      Keyword.get(evaluated_opts, :group_separator, GS1.Consts.gs_symbol())

    fixed_ais_ast = Macro.escape(fixed_ais)

    quote bind_quoted: [gs_symbol: gs_symbol, fixed_ais_ast: fixed_ais_ast] do
      import NimbleParsec

      @min_ai_len 2

      # <GS> char
      gs =
        string(gs_symbol)
        |> ignore()
        |> label("<GS>")

      # can be split into raw_82, raw_39 in future
      raw =
        ascii_string(
          [
            ?A..?Z,
            ?0..?9,
            ?a..?z,
            ?!,
            ?",
            ?%,
            ?&,
            ?',
            ?(,
            ?),
            ?*,
            ?+,
            ?,,
            ?-,
            ?_,
            ?.,
            ?/,
            ?:,
            ?;,
            ?<,
            ?=,
            ?>,
            ??
          ],
          min: 1
        )
        |> label("valid raw char")

      fixed_ai =
        choice(
          Enum.map(fixed_ais_ast, fn {ai, len} ->
            string(ai)
            # only numeric data part in fixed AIs
            |> concat(ascii_string([?0..?9], len - @min_ai_len))
            |> reduce({List, :to_tuple, []})
          end)
        )
        |> unwrap_and_tag(:ai_fixed)
        |> label("fixed-length AI")

      fixed_ai_prefixes =
        choice(Enum.map(fixed_ais_ast, fn {ai, _len} -> string(ai) end))
        |> label("known fixed-length AI prefix")

      var_ai =
        lookahead_not(fixed_ai_prefixes)
        # first elem of tuple is "base" ai
        |> concat(ascii_string([?0..?9], @min_ai_len))
        |> concat(raw)
        # lookahead valid terminator
        |> lookahead(choice([gs, eos()]))
        |> reduce({List, :to_tuple, []})
        |> unwrap_and_tag(:ai_var)
        |> label("variable-length AI")

      segment =
        choice([fixed_ai, var_ai])
        |> optional(gs)
        |> label("AI segment")

      ds =
        times(segment, min: 1)
        |> eos()

      @doc """
      Tokenizes a raw GS1 input string.
      """
      # @spec tokenize(binary(), keyword()) :: GS1.Tokenizer.Base.tokenize_result()
      defparsec :tokenize, ds
    end
  end
end
