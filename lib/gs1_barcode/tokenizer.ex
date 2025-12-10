defmodule GS1.Tokenizer do
  @moduledoc """
  Configured GS1 Tokenizer. See `GS1.Tokenizer.Base`.
  """

  use GS1.Tokenizer.Base,
    fixed_ais: GS1.AIRegistry.fixed_len_ais()
end
