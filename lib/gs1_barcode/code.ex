defmodule GS1.Code do
  @moduledoc """
  Utilities for detecting, validating, creating and normalizing GS1 codes.

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

  @code_types [:gtin8, :gtin12, :gtin13, :gtin14, :sscc]

  @gtin8_upper 10_000_000
  @gtin12_upper 100_000_000_000
  @gtin13_upper 1_000_000_000_000

  @typedoc "Detect error reason."
  @type detect_error :: :invalid_length | :invalid_input | :invalid_digit_or_checksum

  @typedoc "Normalize error reason."
  @type normalize_error :: :cannot_normalize | :sscc_has_no_product_id

  @typedoc "Generate error reason."
  @type generate_error ::
          :invalid_key
          | :invalid_type
          | :key_out_of_bounds
          | :use_to_gtin14
          | :use_build_sscc

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
  Bang version of `detect/1`. Raises an `ArgumentError` if the code is invalid .

  ## Examples

      iex> GS1.Code.detect!("4006381333931")
      :gtin13

      iex> GS1.Code.detect!("123")
      ** (ArgumentError) invalid_length
  """
  @spec detect!(String.t()) :: code_type()
  def detect!(code) do
    case detect(code) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Generates a complete GS1 code GTIN-8,12,13 from integer `key`. For GTIN-14 and SSCC,
  use the corresponding dedicated functions.

  This function is primarily intended for restoring from key representation or generating codes in
  **RCN** (Restricted Circulation Number) ranges (e.g., prefixes 02, 04, 20-29) and other private
  ranges, which are used for internal company purposes, variable measure items, or region-specific applications.

  **Standard GTINs** for commercial use must be obtained from local GS1 MO.
  This function does **not** validate if the generated code falls within an allocated prefix range.

  Returns `{:ok, code}` on success, or `{:error, generate_error()}` on failure.

  ## Examples

      iex> GS1.Code.generate(:gtin13, 200000000034)
      {:ok, "2000000000343"}

      iex> GS1.Code.generate(:gtin14, 200000000034)
      {:error, :use_to_gtin14}
  """
  @spec generate(code_type(), pos_integer()) :: {:error, generate_error()} | {:ok, String.t()}

  def generate(:gtin8, key) when is_integer(key) and key > 0 and key < @gtin8_upper do
    do_generate(key, 8)
  end

  def generate(:gtin12, key) when is_integer(key) and key > 0 and key < @gtin12_upper do
    do_generate(key, 12)
  end

  def generate(:gtin13, key) when is_integer(key) and key > 0 and key < @gtin13_upper do
    do_generate(key, 13)
  end

  def generate(:gtin14, _key), do: {:error, :use_to_gtin14}

  def generate(:sscc, _key), do: {:error, :use_build_sscc}

  def generate(code_type, _) when code_type not in @code_types, do: {:error, :invalid_type}

  def generate(_, key) when is_integer(key), do: {:error, :key_out_of_bounds}

  def generate(_, _), do: {:error, :invalid_key}

  @doc """
  Bang version of `generate/2`. Raises an `ArgumentError` if the code cannot be
  generated (e.g., key is out of bounds, invalid type, or attempts to generate SSCC/GTIN-14).

  ## Examples

      iex> GS1.Code.generate!(:gtin13, 200000000034)
      "2000000000343"

      iex> GS1.Code.generate!(:gtin14, 200000000034)
      ** (ArgumentError) use_to_gtin14
  """
  @spec generate!(code_type(), pos_integer()) :: String.t()
  def generate!(code_type, key) do
    case generate(code_type, key) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Normalizes valid GTIN-8 to a GTIN-12
  Returns error if the input is not a valid GTIN or cannot be normalized to this dimension.

  ## Examples

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
  Bang version of `to_gtin12/1`. Raises `ArgumentError` if the code cannot be detected or normalized.

  ## Examples

      iex> GS1.Code.to_gtin12!("40052441")
      "000040052441"
  """
  @spec to_gtin12!(String.t()) :: String.t()
  def to_gtin12!(code) do
    case to_gtin12(code) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
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

      # GTIN-14 is reduced to GTIN-13 (payload + new check digit calculated)
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
  Bang version of `to_gtin13/1`. Raises `ArgumentError` if the code cannot be detected or normalized.

  ## Examples

      iex> GS1.Code.to_gtin13!("12345670")
      "0000012345670"
  """
  @spec to_gtin13!(String.t()) :: String.t()
  def to_gtin13!(code) do
    case to_gtin13(code) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Normalizes a valid GTIN-8, 12, or 13 to a GTIN-14 with a given Packaging Level Indicator (PLI).

  A PLI can be an int [0, 9] or its character representation.
  * **PLI 0:** Simply pads the input to 14 digits (preserves existing check digit).
  * **PLI 1-9:** Constructs a new hierarchical code and **recalculates the Check Digit**.

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
  Bang version of `to_gtin14/1`. Raises `ArgumentError` if the code cannot be detected or normalized.

  ## Examples

      iex> GS1.Code.to_gtin14!(0, "4006381333931")
      "04006381333931"
  """
  @spec to_gtin14!(non_neg_integer() | char(), String.t()) :: String.t()
  def to_gtin14!(pli, code) do
    case to_gtin14(pli, code) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Generates a valid SSCC (Serial Shipping Container Code) from the Extension Digit,
  GS1 Company Prefix (GCP), and Serial Reference.

  SSCC is an 18-digit number used to identify logistics units, with structure:
  1. **Extension Digit:** 1 digit (0-9).
  2. **GS1 Company Prefix:** variable length.
  3. **Serial Reference:** variable length (padded with leading zeros if needed).
  4. **Check Digit:** 1 digit.

  Function ensures that the combined length of GCP and Serial doesn't exceeds 16 digits,
  and returns an error if the provided `serial` is too long to fit within the remaining
  space allowed by the GCP.

  ## Examples

      iex> GS1.Code.build_sscc(1, "4006381", "12345")
      {:ok, "140063810000123454"}

      # Accepts Extension Digit as char or integer
      iex> GS1.Code.build_sscc(?0, "4006381", "12345")
      {:ok, "040063810000123457"}

      iex> GS1.Code.build_sscc(1, "1234567890123456", "1")
      {:error, :gcp_or_serial_too_long}
  """
  @spec build_sscc(non_neg_integer() | char(), String.t(), String.t()) ::
          {:error, :gcp_or_serial_too_long | :invalid} | {:ok, String.t()}
  def build_sscc(ext, gcp, serial) when ext >= ?0 and ext <= ?9 do
    build_sscc(ext - ?0, gcp, serial)
  end

  def build_sscc(ext, gcp, serial)
      when ext in 0..9 and is_binary(gcp) and
             is_binary(serial) do
    gcp_len = byte_size(gcp)
    serial_len = byte_size(serial)
    serial_max_len = 16 - gcp_len

    if serial_len > serial_max_len do
      {:error, :gcp_or_serial_too_long}
    else
      payload = to_string(ext) <> gcp <> String.pad_leading(serial, serial_max_len, "0")

      case CheckDigit.calculate(payload) do
        {:ok, check} -> {:ok, payload <> to_string(check)}
        {:error, _} -> {:error, :invalid}
      end
    end
  end

  def build_sscc(_ext, _gcp, _serial), do: {:error, :invalid}

  @doc """
  Bang version of `build_sscc/3`. Raises `ArgumentError` if invalid arguments passed.

  ## Examples

      iex> GS1.Code.build_sscc!(1, "4006381", "12345")
      "140063810000123454"
  """
  @spec build_sscc!(non_neg_integer() | char(), String.t(), String.t()) :: String.t()
  def build_sscc!(ext, gcp, serial) do
    case build_sscc(ext, gcp, serial) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Returns payload (part without check digit) of valid code.

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
  Bang version of `payload/1`. Raises `ArgumentError` if code is invalid (detect error).

  ## Examples

      iex> GS1.Code.payload!("4006381333931")
      "400638133393"
  """
  @spec payload!(String.t()) :: String.t()
  def payload!(code) do
    case payload(code) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Casts a valid GS1 GTIN code to its pure **base integer representation** by
  stripping necessary prefixes and **check digit**.

  This representation is the core identification number suitable for storage in a
  database or use as a unique int key for data lookup.

  Logic for extracting the base int is dependent on the detected code type:

  * **SSCC**: cannot be reduced to a key because it doesn't contains product GTIN.
      Returns `{:error, :invalid_key_type}`.
  * **GTIN-14**: base number is derived by stripping both the first char
      **Indicator (PLI)** and trailing **check digit** (last character).
  * **Other GTIN codes**: base number is derived by stripping only the trailing **Check Digit**. The remaining digits are converted to an int.

  ## Examples

      iex> GS1.Code.to_key("11234567890125")
      {:ok, 123456789012} # strips '1' (Indicator) and '8' (Check Digit)

      iex> GS1.Code.to_key("1234567890128")
      {:ok, 123456789012} # strips '8' (Check Digit)

      iex> GS1.Code.to_key("012345679999999997")  # SSCC cannot be converted
      {:error, :invalid_key_type}
  """
  @spec to_key(String.t()) ::
          {:error, :invalid_key_type | detect_error()} | {:ok, pos_integer()}
  def to_key(code) do
    case detect(code) do
      {:ok, :sscc} ->
        {:error, :invalid_key_type}

      {:ok, :gtin14} ->
        {:ok, binary_part(code, 1, byte_size(code) - 2) |> String.to_integer()}

      {:ok, _} ->
        {:ok, binary_part(code, 0, byte_size(code) - 1) |> String.to_integer()}

      error ->
        error
    end
  end

  @doc """
  Bang version of `to_key/1`. Raises `ArgumentError` if the code cannot be detected or normalized.

  ## Examples

      iex> GS1.Code.to_key!("1234567890128")
      123456789012
  """
  @spec to_key!(String.t()) :: pos_integer()
  def to_key!(code) do
    case to_key(code) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, Atom.to_string(reason)
    end
  end

  @doc """
  Lookups country (MO) based on the code prefix.
  Returns `nil` non-country ranges and for GTIN-8 as they use a distinct prefix list.

  ## Examples

      iex> GS1.Code.country("4006381333931")
      [{"Germany", "DE", "DEU", "276"}]
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

  @doc """
  Lookups usage range of the valid code.

  Returns `{:ok, range_type}` if found, `{:ok, nil}` if code valid but not in special range,
  or `{:error, reason}` if the code detection failed

  ## Examples

      iex> GS1.Code.range("2000000000039")
      {:ok, :rcn}

      iex> GS1.Code.range("9781449369996")
      {:ok, :isbn}

      iex> GS1.Code.range("4006381333931") # GTIN for product with country code prefix
      {:ok, nil}
  """
  @spec range(String.t()) :: {:ok, CompanyPrefix.range_type()} | {:error, detect_error()}
  def range(code) do
    case detect(code) do
      {:ok, :gtin8} ->
        {:ok, extract_prefix_gs1(code, :gtin8) |> String.to_integer() |> CompanyPrefix.range8()}

      {:ok, type} ->
        {:ok, extract_prefix_gs1(code, type) |> String.to_integer() |> CompanyPrefix.range()}

      error ->
        error
    end
  end

  @doc """
  Checks if the valid code belongs to a Restricted Circulation Number (RCN) range.

  RCNs are used for internal purposes (e.g., variable measure items like meat/produce sold by weight,
  or internal company codes) and should not be used in open trade.

  ## Examples

      iex> GS1.Code.rcn?("2001234567893")
      true

      iex> GS1.Code.rcn?("4006381333931") # Standard trade item
      false
  """
  @spec rcn?(String.t()) :: boolean()
  def rcn?(code), do: range(code) == {:ok, :rcn}

  @doc """
  Checks if valid code is in range reserved for demonstration or testing.

  ## Examples

      iex> GS1.Code.demo?("9529999199997")
      true
  """
  @spec demo?(String.t()) :: boolean()
  def demo?(code), do: range(code) == {:ok, :demo}

  @doc """
  Checks if valid code is an ISSN (International Standard Serial Number).

  ## Examples

      iex> GS1.Code.issn?("9771234567003")
      true
  """
  @spec issn?(String.t()) :: boolean()
  def issn?(code), do: range(code) == {:ok, :issn}

  @doc """
  Checks if valid code is an ISBN (International Standard Book Number).

  ## Examples

      iex> GS1.Code.isbn?("9783161484100")
      true
  """
  @spec isbn?(String.t()) :: boolean()
  def isbn?(code), do: range(code) == {:ok, :isbn}

  @doc """
  Checks if valid code is a coupon. Detects various coupon formats, including global
  coupons and restricted circulation coupons often used within specific geographic regions.

  ## Examples

      iex> GS1.Code.coupon?("9812345678902")
      true
  """
  @spec coupon?(String.t()) :: boolean()
  def coupon?(code) do
    case range(code) do
      {:ok, :coupon} -> true
      {:ok, :coupon_local} -> true
      _ -> false
    end
  end

  @doc """
  Checks if valid code is a Refund Receipt.

  ## Examples

      iex> GS1.Code.refund?("9800004500008")
      true
  """
  @spec refund?(String.t()) :: boolean()
  def refund?(code), do: range(code) == {:ok, :refund_receipt}

  # Private section

  defp do_generate(key, len) do
    # assuming key is valid always here
    {:ok, check} = CheckDigit.calculate(key)
    key_with_check = key * 10 + check
    {:ok, String.pad_leading(key_with_check |> to_string(), len, "0")}
  end

  defp check(code, type) do
    if CheckDigit.valid?(code) do
      {:ok, type}
    else
      {:error, :invalid_digit_or_checksum}
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

  # build 13-digit payload for GTIN-14, pads lead with extra zeros GTIN-8 and GTIN-12
  defp build_payload14(pli, code) do
    payload_size = byte_size(code) - 1
    code_payload = binary_part(code, 0, payload_size)

    if payload_size == 12 do
      # GTIN-13 with payload size = 12 no needs extra padding
      to_string(pli) <> code_payload
    else
      to_string(pli) <> String.pad_leading(code_payload, 12, "0")
    end
  end
end
