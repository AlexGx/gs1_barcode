defmodule GS1.Code do
  @moduledoc """
  Utilities for detecting, validating, and normalizing GS1 codes.

  Handles GTIN-8 (EAN-8 symbology), GTIN-12 (UPC-A symbology), GTIN-13 (GLN, EAN-13 symbology),
  GTIN-14 (ITF-14 symbology) and SSCC-18.
  """

  alias GS1.CheckDigit
  alias GS1.CompanyPrefix

  @typedoc "Detected code type."
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
  Normalizes valid GTIN-8 to a GTIN-12
  Returns error if the input is not a valid GTIN or cannot be normalized to this dimension.

    ## Example

      iex> GS1.Code.to_gtin12("40052441")
      {:ok, "000040052441"}
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
  Normalizes valid GTIN-8,12 to a GTIN-13.

  GTIN-14 is reduced to GTIN-13 by stripping 1-digit Packaging Level Indicator (PLI) and payload
  with check digit calculation. No additional PLI logic check applied.

  Returns error if the input is not a valid GTIN or cannot be normalized to this dimension.

  ## Examples

      iex> GS1.Code.to_gtin13("12345670")
      {:ok, "0000012345670"}

      # GTIN-14 is reduced to GTIN-13 (payload + new check digit)
      iex> GS1.Code.to_gtin13("10123456789019")
      {:ok, "0123456789012"}
  """
  @spec to_gtin13(String.t()) :: {:ok, String.t()} | {:error, detect_error() | normalize_error()}
  def to_gtin13(code) do
    case detect(code) do
      {:ok, type} when type in [:gtin8, :gtin12] ->
        {:ok, String.pad_leading(code, 13, "0")}

      {:ok, :gtin13} ->
        {:ok, code}

      {:ok, :gtin14} ->
        <<_pli::binary-size(1), payload::binary-size(12), _check::binary-size(1)>> = code
        {:ok, check} = CheckDigit.calculate(payload)
        {:ok, payload <> to_string(check)}

      {:ok, _} ->
        {:error, :cannot_normalize}

      error ->
        error
    end
  end

  @doc """
  Normalizes a valid GTIN-8, 12, or 13 to a GTIN-14 with a given Packaging Level Indicator (PLI).

  A PLI can be an int [0, 9] or its character representation.

  Returns error if the input is not a valid GTIN or cannot be normalized.

  ## Examples

      iex> GS1.Code.to_gtin14(1, "4006381333931")
      {:ok, "14006381333938"}

      iex> GS1.Code.to_gtin14(0, "4006381333931")
      {:ok, "04006381333931"}
  """
  @spec to_gtin14(non_neg_integer() | char(), String.t()) ::
          {:ok, String.t()} | {:error, detect_error() | normalize_error()}

  def to_gtin14(<<pli>>, code) when pli >= ?0 and pli <= ?9 do
    to_gtin14(pli - ?0, code)
  end

  def to_gtin14(0, code) do
    case detect(code) do
      {:ok, type} when type in [:gtin8, :gtin12, :gtin13] ->
        {:ok, String.pad_leading(code, 14, "0")}

      {:ok, _} ->
        {:error, :cannot_normalize}

      error ->
        error
    end
  end

  def to_gtin14(pli, code) when pli in 1..9 do
    case detect(code) do
      {:ok, type} when type in [:gtin8, :gtin12, :gtin13] ->
        payload = build_payload14(pli, code)
        {:ok, check} = CheckDigit.calculate(payload)
        {:ok, payload <> to_string(check)}

      {:ok, _} ->
        {:error, :cannot_normalize}

      error ->
        error
    end
  end

  def to_gtin14(_, _), do: {:error, :invalid_pli}

  @doc """
  Returns payload (part without check digit) of valid code.

  ## Example

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
  Lookups country (Member Organization) based on the prefix.
  """
  @spec country(String.t()) :: CompanyPrefix.country_mo() | {:error, detect_error()}
  def country(code) do
    case detect(code) do
      {:ok, :gtin8} ->
        nil

      {:ok, type} ->
        prefix = extract_prefix_gs1(code, type) |> String.to_integer()
        CompanyPrefix.country(prefix)

      error ->
        error
    end
  end

  @spec range(binary()) :: CompanyPrefix.range_type() | {:error, detect_error()}
  def range(code) do
    case detect(code) do
      {:ok, type} ->
        prefix = extract_prefix_gs1(code, type) |> String.to_integer()
        if type == :gtin8, do: CompanyPrefix.range8(prefix), else: CompanyPrefix.range(prefix)

      error ->
        error
    end
  end

  @spec rcn?(String.t()) :: boolean()
  def rcn?(code), do: range(code) == :rcn

  @spec demo?(String.t()) :: boolean()
  def demo?(code), do: range(code) == :demo

  @spec issn?(String.t()) :: boolean()
  def issn?(code), do: range(code) == :issn

  @spec isbn?(String.t()) :: boolean()
  def isbn?(code), do: range(code) == :isbn

  @spec coupon?(String.t()) :: boolean()
  def coupon?(code), do: range(code) in [:coupon, :coupon_local]

  @spec refund?(String.t()) :: boolean()
  def refund?(code), do: range(code) == :refund_receipt

  # Private section

  defp check(code, type) do
    if CheckDigit.valid?(code) do
      {:ok, type}
    else
      {:error, :invalid_checksum}
    end
  end

  # SSCC & GTIN-14: drop first digit and grab next 3
  defp extract_prefix_gs1(<<_::binary-size(1), prefix::binary-size(3), _::binary>>, :sscc),
    do: prefix

  defp extract_prefix_gs1(<<_::binary-size(1), prefix::binary-size(3), _::binary>>, :gtin14),
    do: prefix

  # GTIN-12: grab the first 2 digits, prepend "0" (may resolve to US or internal-like)
  defp extract_prefix_gs1(<<prefix_part::binary-size(2), _::binary>>, :gtin12),
    do: "0" <> prefix_part

  # all other first 3 digits
  defp extract_prefix_gs1(<<prefix::binary-size(3), _::binary>>, :gtin13), do: prefix
  defp extract_prefix_gs1(<<prefix::binary-size(3), _::binary>>, :gtin8), do: prefix

  # build 13-digit payload for gtin14, pads lead with extra zeros gtin8 and gtin12
  defp build_payload14(pli, code) do
    payload_size = byte_size(code) - 1
    code_payload = binary_part(code, 0, payload_size)

    if payload_size == 12 do
      # gtin13 with payload size = 12 no needs extra padding
      to_string(pli) <> code_payload
    else
      to_string(pli) <> String.pad_leading(code_payload, 12, "0")
    end
  end
end
