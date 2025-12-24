defmodule GS1.Utils do
  @moduledoc """
  Utility functions for:

  * GLN validation
  * Converting AI data with implied decimal points into floats.
  * Converting between GS1 20-digit location strings and WGS84 lat/long coordinates and vice versa.
  """

  alias GS1.Code

  @doc """
  Validates whether a code structure matches a GLN (Global Location Number).
  A GLN is structurally identical to a GTIN-13 but relies on context.

  ## Examples

      iex> GS1.Utils.valid_gln?("4006381333931")
      true
  """
  @spec valid_gln?(String.t()) :: boolean()
  def valid_gln?(code) do
    case Code.detect(code) do
      {:ok, :gtin13} -> true
      _ -> false
    end
  end

  @doc """
  Extracts an ISO currency code and amount value from ISO AI data string containing an ISO currency code prefix followed by an amount
  with an implied decimal point into structured data.

  This function is used for AIs like "391n" where the data field consists of:
  * a 3-digit ISO 4217 currency code (e.g., "978" for EUR, "840" for USD)
  * Amount with an implied decimal point position (`n` part from AI)

  See `data_to_float/2` for the underlying amount conversion logic.

  ## Parameters
  * `data` - AI data string starting with a 3-digit ISO currency code followed by the amount
    (e.g., `"978150"` for €1.50 when `dec_places` is 2).
  * `dec_places` - number of digits after the implied decimal point.

  ## Returns
  * `{:ok, iso_code_str, float_amount}` - on success; note that ISO 4217 currency code validation is **not** performed.
  * `{:error, :invalid}` - if the ISO code or amount cannot be parsed.
  * `{:error, :len_mismatch}` - if the amount part is too short for the given decimal places.

  ## Examples

      iex> GS1.Utils.data_iso_to_float("978150", 2)
      {:ok, "978", 1.5}

      iex> GS1.Utils.data_iso_to_float("8401000", 0)
      {:ok, "840", 1000.0}

      iex> GS1.Utils.data_iso_to_float("978099", 2)
      {:ok, "978", 0.99}
  """
  @spec data_iso_to_float(String.t(), any()) ::
          {:error, :invalid | :len_mismatch} | {:ok, String.t(), float()}
  def data_iso_to_float(<<iso::binary-size(3), value::binary>>, dec_places)
      when is_integer(dec_places) and dec_places >= 0 do
    case Integer.parse(iso) do
      {_iso_int, ""} ->
        case data_to_float(value, dec_places) do
          {:ok, value} -> {:ok, iso, value}
          error -> error
        end

      _ ->
        {:error, :invalid}
    end
  end

  def data_iso_to_float(_, _), do: {:error, :invalid}

  @doc """
  Converts data string AIs (like "310x", "320x", etc.), which may contain an
  implied decimal point, into a float.

  The `dec_places` parameter specifies how many digits from the right of the string
  represent the fractional part. See GenSpec section 7.8.7: "Application Identifiers with implied
  decimal point positions".

  ## Parameters
  * `data` - AI data part (e.g., `"3000200"`).
  * `dec_places` - number of digits after the implied decimal point (e.g., `3`).

  ## Returns
  * `{:ok, float()}` - if conversion is successful.
  * `{:error, :invalid}` - if the resulting string cannot be parsed as a float.
  * `{:error, :len_mismatch}` - if the length of `data` is less than or equal to `dec_places`.

  ## Examples

      iex> GS1.Utils.data_to_float("3000200", 3)
      {:ok, 3000.2}
  """
  @spec data_to_float(String.t(), non_neg_integer()) ::
          {:error, :invalid | :len_mismatch} | {:ok, float()}

  def data_to_float(data, 0) when is_binary(data) do
    case Float.parse(data) do
      {float, ""} -> {:ok, float}
      _ -> {:error, :invalid}
    end
  end

  def data_to_float(data, dec_places)
      when is_binary(data) and is_integer(dec_places) and dec_places > 0 do
    len = String.length(data)

    if len <= dec_places do
      {:error, :len_mismatch}
    else
      {whole, frac} = String.split_at(data, -dec_places)

      case Float.parse(whole <> "." <> frac) do
        {float, ""} -> {:ok, float}
        _ -> {:error, :invalid}
      end
    end
  end

  def data_to_float(_, _), do: {:error, :invalid}

  @doc """
  Converts a 20-character data string (e.g., AI "8200") to WGS84 lat, lon coords.

  Input is split into two 10-character parts:
  * First 10 characters encode **latitude** (X).
  * Second 10 characters encode **longitude** (Y).

  The conversion logic is defined by GS1 specifications for location encoding.

  ## Parameters
  * `data`: A 20-character binary/string containing the encoded coordinates.

  ## Returns
  * `{:ok, {latitude, longitude}}` - where both values are floats.
  * `{:error, :invalid}` -  if the input is not a 20-character binary or the parts are invalid.

  ## Examples

      iex> GS1.Utils.string_20_to_wgs84_lat_log("02790858483015297971")
      {:ok, {-62.0914152, -58.470202900000004}}
  """
  @spec string_20_to_wgs84_lat_log(String.t()) :: {:error, :invalid} | {:ok, {float(), float()}}
  def string_20_to_wgs84_lat_log(<<x::binary-size(10), y::binary-size(10)>>) do
    lat_deg =
      case Integer.parse(x) do
        {x_int, ""} -> to_wgs84_latitude_deg(x_int)
        _ -> nil
      end

    lon_deg =
      case Integer.parse(y) do
        {y_int, ""} -> to_wgs84_longitude_deg(y_int)
        _ -> nil
      end

    if lat_deg != nil and lon_deg != nil do
      {:ok, {lat_deg, lon_deg}}
    else
      {:error, :invalid}
    end
  end

  def string_20_to_wgs84_lat_log(_), do: {:error, :invalid}

  @doc """
  Converts WGS84 lat, lon coords to a 20-character GS1-encoded string.

  The resulting string is formatted as a 10-digit encoded latitude followed by a 10-digit encoded longitude.
  Each encoded integer is padded with leading zeros to ensure a 10-character length.
  This is the reverse operation of `string_20_to_wgs84_lat_log/1`.

  ## Parameters
  * `lat_deg`: WGS84 latitude in decimal degrees ($-90.0$ to $90.0$).
  * `lon_deg`: WGS84 longitude in decimal degrees ($-180.0$ to $180.0$).

  ## Returns
  * `{:ok, String.t()}` - 20-character encoded string.
  * `{:error, :invalid_lat_lon}` - when input coordinates are outside the valid WGS84 range.

  ## Examples

      iex> GS1.Utils.wgs84_lat_log_to_string_20(-62.0914152, -58.470202900000004)
      {:ok, "02790858483015297971"}
  """
  @spec wgs84_lat_log_to_string_20(float(), float()) ::
          {:ok, String.t()} | {:error, :invalid_lat_lon}
  def wgs84_lat_log_to_string_20(lat_deg, lon_deg) do
    case wgs84_lat_log_to_ints(lat_deg, lon_deg) do
      {:ok, {x, y}} ->
        {:ok,
         String.pad_leading(x |> to_string, 10, "0") <>
           String.pad_leading(y |> to_string, 10, "0")}

      error ->
        error
    end
  end

  @doc """
  Converts WGS84 lat/lon coordinates into the integer representation used by GS1.

  This function applies the offset and scaling factors defined in the GS1 General Specifications
  but does not format them into the final data field string.

  ## Parameters
  * `lat_deg`: WGS84 latitude in decimal degrees ([-90.0, 90.0]).
  * `lon_deg`: WGS84 longitude in decimal degrees ([-180.0 and 180.0]).

  ## Returns
  * `{:ok, {x_int, y_int}}` - int representations of latitude and longitude.
  * `{:error, :invalid_lat_lon}` - error if the coordinates are out of range.

  ## Examples

        iex> GS1.Utils.wgs84_lat_log_to_ints(-62.0914152, -58.470202900000004)
        {:ok, {279085848, 3015297971}}
  """
  @spec wgs84_lat_log_to_ints(float(), float()) ::
          {:ok, {non_neg_integer(), non_neg_integer()}} | {:error, :invalid_lat_lon}
  def wgs84_lat_log_to_ints(lat_deg, lon_deg)
      when is_float(lat_deg) and is_float(lon_deg) and
             lat_deg >= -90.0 and lat_deg <= 90.0 and
             lon_deg >= -180.0 and lon_deg <= 180.0 do
    # X = 10,000,000 * (WGS84 latitude + 90)
    x = 10_000_000 * (lat_deg + 90)

    # Y = 10,000,000 * ((WGS84 longitude + 360) mod 360)
    long_deg_norm = lon_deg + 360
    y = 10_000_000 * long_deg_norm - 360 * floor(long_deg_norm / 360)

    {:ok, {trunc(x), trunc(y)}}
  end

  def wgs84_lat_log_to_ints(_, _), do: {:error, :invalid_lat_lon}

  @doc """
  Decodes the integer `X` component of the GS1 location string back into a WGS84 latitude.

  ## Examples

        iex> GS1.Utils.to_wgs84_latitude_deg(0279085848)
        -62.0914152
  """
  @spec to_wgs84_latitude_deg(non_neg_integer()) :: nil | float()
  def to_wgs84_latitude_deg(x) when is_integer(x) do
    x / 10_000_000 - 90
  end

  def to_wgs84_latitude_deg(_), do: nil

  @doc """
  Decodes the integer `Y` component of the GS1 location string back into a WGS84 longitude.

  ## Examples

        iex> GS1.Utils.to_wgs84_longitude_deg(3015297971)
        -58.470202900000004
  """
  @spec to_wgs84_longitude_deg(non_neg_integer()) :: nil | float()
  def to_wgs84_longitude_deg(y) when is_integer(y) do
    normalized_value = y / 10_000_000 + 180
    normalized_value - 360 * floor(normalized_value / 360) - 180.0
  end

  def to_wgs84_longitude_deg(_), do: nil
end
