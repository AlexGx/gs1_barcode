defmodule GS1.Code do
  @moduledoc """
  Utilities for detecting, validating, and normalizing GS1 codes.

  Handles GTIN-8 (EAN-8 symbology), GTIN-12 (UPC-A symbology), GTIN-13 (GLN, EAN-13 symbology),
  GTIN-14 (ITF-14) and SSCC-18.
  """

  alias GS1.CheckDigit
  alias GS1.CountryCode

  @typedoc "Detected type."
  @type code_type ::
          :gtin8
          | :gtin12
          | :gtin13
          | :gtin14
          | :sscc

  @type detect_error :: :invalid_length | :invalid_input | :invalid_checksum

  @type normalize_error :: :cannot_normalize | :sscc_has_no_product_id

  @doc """
  Detects valid GS1 code and returns type.

  ## Examples

      iex> GS1.Code.detect("4006381333931")
      {:ok, :gtin13}

      iex> GS1.Code.detect("123")
      {:error, :invalid_length}
  """
  @spec detect(String.t()) :: {:ok, code_type()} | {:error, detect_error()}

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

  ## Examples

      iex> GS1.Code.to_gtin14("4006381333931")
      {:ok, "04006381333931"}
  """
  @spec to_gtin14(String.t()) :: {:ok, String.t()} | {:error, detect_error() | normalize_error()}
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
  @spec to_gtin13(String.t()) :: {:ok, String.t()} | {:error, detect_error() | normalize_error()}
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
  @spec to_gtin12(String.t()) :: {:ok, String.t()} | {:error, detect_error() | normalize_error()}
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

  @doc """
  Returns the barcode digits excluding the check digit.

  ## Examples

      iex> GS1.Code.payload("4006381333931")
      {:ok, "400638133393"}
  """
  @spec payload(String.t()) :: {:ok, String.t()} | {:error, detect_error()}
  def payload(code) do
    case detect(code) do
      {:ok, _} ->
        {:ok, binary_part(code, 0, byte_size(code) - 1)}

      error ->
        error
    end
  end

  @doc """
  Detects if the code belongs to a Restricted Circulation Number (RCN) range.
  Typically used for internal variable measure items (020-029)
  or internal restricted use (040-049).
  """
  @spec detect_internal(String.t()) :: {:ok, boolean()} | {:error, detect_error()}
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

  @doc """
  Looks up the country / GS1 Member Organization based on the prefix.
  """
  @spec country_lookup(String.t()) :: CountryCode.lookup_result() | {:error, detect_error()}
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

  @doc """
  Returns the 'Base GTIN' (unit level) for database matching.
  - GTIN-12 becomes 13 digits (padded with 0).
  - GTIN-14 has the Indicator Digit stripped (returning 13 digits).
  - SSCC cannot be converted to a product key.
  """
  @spec to_key(String.t()) :: {:ok, String.t()} | {:error, detect_error() | normalize_error()}
  def to_key(code) do
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
  @spec valid_gln?(String.t()) :: boolean()
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

  # SSCC & GTIN-14: drop first digit and grab next 3
  defp prefix_code(<<_::binary-size(1), prefix::binary-size(3), _::binary>>, t)
       when t in [:sscc, :gtin14] do
    prefix
  end

  # GTIN-12: grab the first 2 digits, prepend "0" (may resolve to US or internal-like)
  defp prefix_code(<<prefix_part::binary-size(2), _::binary>>, :gtin12), do: "0" <> prefix_part

  defp prefix_code(<<prefix::binary-size(3), _::binary>>, _), do: prefix
end
