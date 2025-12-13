defmodule GS1.Tokenizer do
  @moduledoc """
  Configured GS1 Tokenizer. See `GS1.Tokenizer.Base`.

  ## Example

      iex> GS1.Tokenizer.tokenize("010460049469420217210228")
      {:ok, [
        ai_fixed: {"01", "04600494694202"},
        ai_fixed: {"17", "210228"}
      ], "", %{}, {1, 0}, 24}
  """

  use GS1.Tokenizer.Base,
    fixed_ais: GS1.AIRegistry.fixed_len_ais()
end
