defmodule GS1.CheckDigit do
  @moduledoc """
  GS1 Modulo-10 check digit validation GTINs. Accepts digit-only binaries.
  """

  @doc """
  Validates a digit-only binary string.

  ## Examples

    iex> GS1.CheckDigit.valid?("012345678905")
    true
  """
  @spec valid?(String.t()) :: boolean()
  def valid?(code) when is_binary(code) do
    case byte_size(code) do
      0 ->
        false

      len ->
        # even length strings (GTIN-8/12/14) start with weight=3.
        # odd length strings (GTIN-13) start with weight=1.
        start_weight = if rem(len, 2) == 0, do: 3, else: 1
        check_digits(code, start_weight, 0)
    end
  end

  def valid?(_), do: false

  # at end check sum is divisible by 10
  defp check_digits(<<>>, _weight, sum), do: rem(sum, 10) == 0

  # ?0 is the ASCII int for '0', subtract it to get the real value.
  defp check_digits(<<char, rest::binary>>, weight, sum) when char >= ?0 and char <= ?9 do
    digit = char - ?0
    new_sum = sum + digit * weight

    # toggle weight
    new_weight = 4 - weight

    check_digits(rest, new_weight, new_sum)
  end

  # non-digit character
  defp check_digits(_, _, _), do: false
end
