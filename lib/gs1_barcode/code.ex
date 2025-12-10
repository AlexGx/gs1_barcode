defmodule GS1.Code do
  @moduledoc false

  alias GS1.CheckDigit
  alias GS1.CountryCode

  # EAN-8 is symbology!
  @type code_type ::
          :gtin8
          # UPC-A is symbology!
          | :gtin12
          # EAN-13 is symbology!
          | :gtin13
          | :gtin14
          | :sscc

  @doc """
  Detects valid GS1 code and returns type.
  """
  @spec detect(String.t()) :: {:ok, code_type()} | {:error, atom()}

  def detect(<<_::binary-size(8)>> = code), do: check(code, :gtin8)
  def detect(<<_::binary-size(12)>> = code), do: check(code, :gtin12)
  def detect(<<_::binary-size(13)>> = code), do: check(code, :gtin13)
  def detect(<<_::binary-size(14)>> = code), do: check(code, :gtin14)
  def detect(<<_::binary-size(18)>> = code), do: check(code, :sscc)

  def detect(code) when is_binary(code), do: {:error, :invalid_length}

  def detect(_), do: {:error, :invalid_input}

  @doc """
  Normalizes valid GTIN-8,12,13 to a GTIN-14.
  Returns error if the input is not a valid GTIN or is already SSCC (18 digits).
  """
  def to_gtin14(code) do
    case detect(code) do
      {:ok, type} when type in [:gtin8, :gtin12, :gtin13, :gtin14] ->
        {:ok, String.pad_leading(code, 14, "0")}

      {:ok, _} ->
        {:error, :cannot_normalize}

      error ->
        error
    end
  end

  @doc """
  Normalizes valid GTIN-8,12 to a GTIN-13.
  Returns error if the input is not a valid GTIN or is already SSCC (18 digits).
  """
  def to_gtin13(code) do
    case detect(code) do
      {:ok, type} when type in [:gtin8, :gtin12, :gtin13] ->
        {:ok, String.pad_leading(code, 13, "0")}

      {:ok, _} ->
        {:error, :cannot_normalize}

      error ->
        error
    end
  end

  @doc """
  Normalizes valid GTIN-8 to a GTIN-12
  Returns error if the input is not a valid GTIN or is already SSCC (18 digits).
  """
  def to_gtin12(code) do
    case detect(code) do
      {:ok, type} when type == :gtin8 ->
        {:ok, String.pad_leading(code, 12, "0")}

      {:ok, _} ->
        {:error, :cannot_normalize}

      error ->
        error
    end
  end

  @doc "Returns the barcode digits excluding the check digit."
  def payload(code) do
    case detect(code) do
      {:ok, _} ->
        {:ok, binary_part(code, 0, byte_size(code) - 1)}

      error ->
        error
    end
  end

  def detect_internal(code) do
    case detect(code) do
      {:ok, type} ->
        prefix_as_int = prefix_code(code, type) |> String.to_integer()
        internal? = prefix_as_int in 020..029 or prefix_as_int in 040..049
        {:ok, internal?}

      error ->
        error
    end
  end

  def country_lookup(code) do
    case detect(code) do
      # {:ok, :gtin8} -> #special case for gtin-8 Poland and UK ?
      {:ok, type} ->
        prefix_as_int = prefix_code(code, type) |> String.to_integer()
        CountryCode.lookup(prefix_as_int)

      error ->
        error
    end
  end

  @doc "Returns the 'Base GTIN' (unit level) for matching."
  def to_lookup_key(code) do
    case detect(code) do
      # convert UPC to EAN-13
      {:ok, :gtin12} ->
        {:ok, "0" <> code}

      {:ok, :gtin14} ->
        <<_::binary-size(1), base::binary>> = code
        {:ok, base}

      {:ok, :gtin13} ->
        {:ok, code}

      {:ok, :gtin8} ->
        {:ok, code}

      {:ok, :sscc} ->
        {:error, :sscc_has_no_product_id}

      error ->
        error
    end
  end

  @doc """
  Validates if a code structure matches a GLN (Global Location Number).
  GLN is structurally identical to a GTIN-13 but relies on context.
  """
  def valid_gln?(code) do
    case detect(code) do
      {:ok, :gtin13} -> true
      _ -> false
    end
  end

  # Private section

  defp check(code, type) do
    if CheckDigit.valid?(code) do
      {:ok, type}
    else
      {:error, :invalid_checksum}
    end
  end

  # SSCC & GTIN-14: drop 1st digit and grab next 3
  defp prefix_code(<<_::binary-size(1), prefix::binary-size(3), _::binary>>, t)
       when t in [:sscc, :gtin14] do
    prefix
  end

  # GTIN-12: grab the first 2 digits, prepend "0" (may resolve to US or internal-like)
  defp prefix_code(<<prefix_part::binary-size(2), _::binary>>, :gtin12), do: "0" <> prefix_part

  defp prefix_code(<<prefix::binary-size(3), _::binary>>, _), do: prefix
end
