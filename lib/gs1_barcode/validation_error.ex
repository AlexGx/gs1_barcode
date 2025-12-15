defmodule GS1.ValidationError do
  @moduledoc """
  Single validation rule error.
  """

  @typedoc """
  Validation error code.

    * `:invalid_check_digit` - AI data field failed with checksum validation.
    * `:invalid_date` - AI date field (YYMMDD) validation failed
    * `:missing_ai` - Required AI missing in Data Structure.
    * `:forbidden_ai` - AI was present in Data Structure that is not allowed in validation context.
    * `:constraint_ai` - AI violates constraint check.
  """
  @type code ::
          :invalid_check_digit
          | :invalid_date
          | :missing_ai
          | :forbidden_ai
          | :constraint_ai

  @typedoc """
  Validation error struct.

  ### Fields

    * `:code` - error code (see `t:code/0`).
    * `:ai` - Application Identifier (AI) associated with the error.
    * `:message` - user friendly error message.
  """
  @type t :: %__MODULE__{
          code: code(),
          ai: String.t(),
          message: String.t()
        }

  @enforce_keys [:code, :ai, :message]

  defstruct [:code, :ai, :message]
end
