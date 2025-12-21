defmodule GS1.UtilsTest do
  use ExUnit.Case, async: true

  doctest GS1.Utils

  alias GS1.Utils

  describe "valid_gln?/1" do
    test "returns true for a string that Code.detect/1 identifies as :gtin13" do
      # A real GTIN-13 structure
      gln_candidate = "4006381333931"
      assert Utils.valid_gln?(gln_candidate) == true
    end

    test "returns false for a string that is not a GTIN-13" do
      not_gln = "12345"
      assert Utils.valid_gln?(not_gln) == false
    end

    test "returns false for a valid code that is not a GTIN-13 (e.g., GTIN-8)" do
      other_code = "12345670"
      assert Utils.valid_gln?(other_code) == false
    end
  end

  describe "data_iso_to_float/2" do
    @iso_eur "978"
    @iso_usd "840"

    test "converts iso data with an implied decimal point correctly" do
      assert Utils.data_iso_to_float(@iso_eur <> "3000200", 3) == {:ok, @iso_eur, 3000.2}
      assert Utils.data_iso_to_float(@iso_usd <> "12345", 2) == {:ok, @iso_usd, 123.45}
      assert Utils.data_iso_to_float(@iso_eur <> "0005", 3) == {:ok, @iso_eur, 0.005}
      assert Utils.data_iso_to_float(@iso_usd <> "10", 1) == {:ok, @iso_usd, 1.0}
    end

    test "converts iso data with zero decimal places correctly" do
      assert Utils.data_iso_to_float(@iso_eur <> "12345", 0) == {:ok, @iso_eur, 12_345.0}
      assert Utils.data_iso_to_float(@iso_usd <> "0", 0) == {:ok, @iso_usd, 0.0}
    end

    test "returns :len_mismatch when iso data length is less than dec_places" do
      assert Utils.data_iso_to_float(@iso_eur <> "123", 4) == {:error, :len_mismatch}
      assert Utils.data_iso_to_float(@iso_eur <> "1", 2) == {:error, :len_mismatch}
      assert Utils.data_iso_to_float(@iso_usd <> "1", 1) == {:error, :len_mismatch}
    end

    test "returns :len_mismatch when iso data length is equal to dec_places" do
      assert Utils.data_iso_to_float(@iso_usd <> "123", 3) == {:error, :len_mismatch}
    end

    # Error cases: :invalid

    test "returns :invalid for non-numeric iso data when dec_places is > 0" do
      assert Utils.data_iso_to_float(@iso_eur <> "12a45", 2) == {:error, :invalid}
      assert Utils.data_iso_to_float(@iso_usd <> "", 1) == {:error, :len_mismatch}
    end

    test "returns :invalid for non-numeric iso data when dec_places is 0" do
      assert Utils.data_iso_to_float(@iso_eur <> "12a45", 0) == {:error, :invalid}
      assert Utils.data_iso_to_float(@iso_eur <> "", 0) == {:error, :invalid}
    end

    test "returns :invalid when ISO part is invalid" do
      assert Utils.data_iso_to_float("USD" <> "3000200", 3) == {:error, :invalid}
      assert Utils.data_iso_to_float("X93" <> "12345", 2) == {:error, :invalid}
    end

    test "returns :invalid for non-string iso data or invalid `dec_places`" do
      assert Utils.data_iso_to_float(12_345, 2) == {:error, :invalid}
      assert Utils.data_iso_to_float(nil, 2) == {:error, :invalid}
      assert Utils.data_iso_to_float("12345", :two) == {:error, :invalid}
    end
  end

  describe "data_to_float/2" do
    test "converts data with an implied decimal point correctly" do
      assert Utils.data_to_float("3000200", 3) == {:ok, 3000.2}
      assert Utils.data_to_float("12345", 2) == {:ok, 123.45}
      assert Utils.data_to_float("0005", 3) == {:ok, 0.005}
      assert Utils.data_to_float("10", 1) == {:ok, 1.0}
    end

    test "converts data with zero decimal places correctly" do
      assert Utils.data_to_float("12345", 0) == {:ok, 12_345.0}
      assert Utils.data_to_float("0", 0) == {:ok, 0.0}
    end

    test "returns :len_mismatch when data length is less than dec_places" do
      assert Utils.data_to_float("123", 4) == {:error, :len_mismatch}
      assert Utils.data_to_float("1", 2) == {:error, :len_mismatch}
      assert Utils.data_to_float("1", 1) == {:error, :len_mismatch}
    end

    test "returns :len_mismatch when data length is equal to dec_places" do
      assert Utils.data_to_float("123", 3) == {:error, :len_mismatch}
    end

    # Error cases: :invalid

    test "returns :invalid for non-numeric data when dec_places is > 0" do
      assert Utils.data_to_float("12a45", 2) == {:error, :invalid}
      assert Utils.data_to_float("", 1) == {:error, :len_mismatch}
    end

    test "returns :invalid for non-numeric data when dec_places is 0" do
      assert Utils.data_to_float("12a45", 0) == {:error, :invalid}
      assert Utils.data_to_float("", 0) == {:error, :invalid}
    end

    test "returns :invalid for non-string data" do
      assert Utils.data_to_float(12_345, 2) == {:error, :invalid}
      assert Utils.data_to_float(nil, 2) == {:error, :invalid}
      assert Utils.data_to_float("12345", :two) == {:error, :invalid}
    end
  end

  describe "string_20_to_wgs84_lat_log/1 and wgs84_lat_log_to_string_20/2" do
    @assert_delta 0.00000001
    @lat_ref -62.0914152
    @lon_ref -58.470202900000004
    @string_ref "02790858483015297971"

    test "string_20_to_wgs84_lat_log/1 converts reference string to coords" do
      {:ok, {lat, lon}} = Utils.string_20_to_wgs84_lat_log(@string_ref)
      assert_in_delta(lat, @lat_ref, @assert_delta)
      assert_in_delta(lon, @lon_ref, @assert_delta)
    end

    test "wgs84_lat_log_to_string_20/2 converts reference coords to string" do
      assert Utils.wgs84_lat_log_to_string_20(@lat_ref, @lon_ref) == {:ok, @string_ref}
    end

    test "wgs84_lat_log_to_string_20/2 handles coordinates near the poles and antimeridian" do
      # North Pole (90.0, 0.0)
      assert Utils.wgs84_lat_log_to_string_20(90.0, 0.0) == {:ok, "18000000003599999640"}

      # South Pole (-90.0, 0.0)
      assert Utils.wgs84_lat_log_to_string_20(-90.0, 0.0) == {:ok, "00000000003599999640"}

      # international Date Line (180.0)
      assert Utils.wgs84_lat_log_to_string_20(0.0, 180.0) == {:ok, "09000000005399999640"}

      # international Date Line (-180.0)
      assert Utils.wgs84_lat_log_to_string_20(0.0, -180.0) == {:ok, "09000000001800000000"}
    end

    test "string_20_to_wgs84_lat_log/1 handles string errors" do
      # incorrect length (less than 20)
      assert Utils.string_20_to_wgs84_lat_log("1234567890123456789") == {:error, :invalid}
      # incorrect length (more than 20)
      assert Utils.string_20_to_wgs84_lat_log("123456789012345678901") == {:error, :invalid}
      # non-numeric characters in the string
      assert Utils.string_20_to_wgs84_lat_log("123456789a1234567890") == {:error, :invalid}
      assert Utils.string_20_to_wgs84_lat_log("1234567890123456789!") == {:error, :invalid}
      # non-string input
      assert Utils.string_20_to_wgs84_lat_log(12_345) == {:error, :invalid}
    end

    test "wgs84_lat_log_to_string_20/2 handles out-of-range coordinates" do
      # invalid Latitude (too high)
      assert Utils.wgs84_lat_log_to_string_20(90.1, 0.0) == {:error, :invalid_lat_lon}
      # invalid Latitude (too low)
      assert Utils.wgs84_lat_log_to_string_20(-90.1, 0.0) == {:error, :invalid_lat_lon}
      # invalid Longitude (too high)
      assert Utils.wgs84_lat_log_to_string_20(0.0, 180.1) == {:error, :invalid_lat_lon}
      # invalid Longitude (too low)
      assert Utils.wgs84_lat_log_to_string_20(0.0, -180.1) == {:error, :invalid_lat_lon}
      # non-float input
      assert Utils.wgs84_lat_log_to_string_20(0, 0) == {:error, :invalid_lat_lon}
      assert Utils.wgs84_lat_log_to_string_20(:lat, :lon) == {:error, :invalid_lat_lon}
    end
  end

  describe "Coordinate Helper Functions" do
    @lat_ref -62.0914152
    @lon_ref -58.470202900000004
    # encoded Latitude
    @x_ref 279_085_848
    # encoded Longitude
    @y_ref 3_015_297_971

    test "wgs84_lat_log_to_ints/2 converts float coords to encoded integers" do
      assert Utils.wgs84_lat_log_to_ints(@lat_ref, @lon_ref) == {:ok, {@x_ref, @y_ref}}
      assert Utils.wgs84_lat_log_to_ints(90.0, 0.0) == {:ok, {1_800_000_000, 3_599_999_640}}
    end

    test "to_wgs84_latitude_deg/1 converts encoded latitude back to degrees" do
      # reference value
      assert Utils.to_wgs84_latitude_deg(@x_ref) == @lat_ref
      # 0 (South Pole)
      assert Utils.to_wgs84_latitude_deg(0) == -90.0
      # 1800000000 (North Pole)
      assert Utils.to_wgs84_latitude_deg(1_800_000_000) == 90.0
      # non-integer input
      assert Utils.to_wgs84_latitude_deg(4.5) == nil
    end

    test "to_wgs84_longitude_deg/1 converts encoded longitude back to degrees" do
      # reference value
      assert Utils.to_wgs84_longitude_deg(@y_ref) == @lon_ref
      assert Utils.to_wgs84_longitude_deg(0) == 0.0
      assert Utils.to_wgs84_longitude_deg(1_800_000_000) == -180.0
      assert Utils.to_wgs84_longitude_deg(3_600_000_000) == 0.0
      # Test with non-integer input
      assert Utils.to_wgs84_longitude_deg(4.5) == nil
    end
  end
end
