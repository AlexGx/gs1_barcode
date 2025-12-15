defmodule GS1.CheckDigit do
  @moduledoc """
  GS1 Modulo-10 check digit code validation. Accepts digit-only binaries.
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
        # even length strings (SSCC/GTIN-8,12,14) start with weight=3.
        # odd length strings GTIN-13 start with weight=1
        start_weight = if rem(len, 2) == 0, do: 3, else: 1

        case sum_digits(code, start_weight, 0) do
          {:ok, sum} -> rem(sum, 10) == 0
          {:error, _} -> false
        end
    end
  end

  def valid?(_), do: false

  @doc """
  Calculates check digit.

  ## Examples

      iex> GS1.CheckDigit.calculate("01234567890")
      {:ok, 5}

      iex> GS1.CheckDigit.calculate("ABC")
      {:error, :non_digit}

      iex> GS1.CheckDigit.calculate(5762654)
      {:ok, 3}
  """
  @spec calculate(String.t() | pos_integer()) :: {:ok, non_neg_integer()} | {:error, term()}

  def calculate(code) when is_integer(code) and code > 0 do
    calculate(code |> Integer.to_string())
  end

  def calculate(code) when is_binary(code) do
    case byte_size(code) do
      0 ->
        {:error, :empty}

      len ->
        # same as in `valid?/1`.
        start_weight = if rem(len, 2) != 0, do: 3, else: 1

        do_calculate(code, start_weight)
    end
  end

  def calculate(_), do: {:error, :invalid}

  # Private section

  defp sum_digits(<<>>, _weight, sum), do: {:ok, sum}

  # ?0 is the ASCII int for '0', subtract it to get the real value.
  defp sum_digits(<<char, rest::binary>>, weight, sum) when char >= ?0 and char <= ?9 do
    digit = char - ?0

    new_sum = sum + digit * weight

    # toggle weight
    new_weight = 4 - weight

    sum_digits(rest, new_weight, new_sum)
  end

  defp sum_digits(_, _, _), do: {:error, :non_digit}

  defp do_calculate(code, start_weight) do
    case sum_digits(code, start_weight, 0) do
      {:ok, sum} ->
        # smallest num to add to make sum divisible by 10
        remainder = rem(sum, 10)
        check_digit = if remainder == 0, do: 0, else: 10 - remainder
        {:ok, check_digit}

      error ->
        error
    end
  end
end
