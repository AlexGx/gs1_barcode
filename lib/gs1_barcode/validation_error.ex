defmodule GS1.ValidationError do
  @moduledoc """
  Single validation rule error.
  """

  @type code ::
          :invalid_check_digit
          | :invalid_date
          | :missing_ai
          | :forbidden_ai
          | :constraint_ai

  @type t :: %__MODULE__{
          code: code(),
          ai: String.t(),
          message: String.t()
        }

  @enforce_keys [:code, :ai, :message]

  defstruct [:code, :ai, :message]
end
