defmodule GS1.Utils do
  @moduledoc false

  alias GS1.Code

  @doc """
  Validates if a code structure matches a GLN (Global Location Number).
  GLN is structurally identical to a GTIN-13 but relies on context.

  ## Example

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
  ## Example

      iex> GS1.Utils.string_20_to_wgs84_lat_log("02790858483015297971")
      {:ok, {-62.0914152, -58.470202900000004}}
  """
  @spec string_20_to_wgs84_lat_log(any()) :: {:error, :invalid} | {:ok, {float(), float()}}
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
  ## Example

      iex> GS1.Utils.wgs84_lat_log_to_string_20(-62.0914152, -58.470202900000004)
      "02790858483015297971"
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
  ## Example

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
  ## Example

        iex> GS1.Utils.to_wgs84_latitude_deg(0279085848)
        -62.0914152
  """
  @spec to_wgs84_latitude_deg(non_neg_integer()) :: nil | float()
  def to_wgs84_latitude_deg(x) when is_integer(x) do
    x / 10_000_000 - 90
  end

  def to_wgs84_latitude_deg(_), do: nil

  @doc """
  ## Example

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
