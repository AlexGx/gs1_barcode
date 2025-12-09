defmodule GS1.DateUtilsTest do
  use ExUnit.Case, async: true

  alias GS1.DateUtils

  describe "valid?/2 with :yymmdd format" do
    test "returns true for a valid date in the 21st century (e.g., 2025-12-31)" do
      assert DateUtils.valid?(:yymmdd, "251231")
    end

    test "returns true for a date at the beginning of the century (2000-01-01)" do
      assert DateUtils.valid?(:yymmdd, "000101")
    end

    test "returns true for a future date (2099-12-31)" do
      assert DateUtils.valid?(:yymmdd, "991231")
    end

    test "returns true for a valid leap day (2024-02-29)" do
      # 2024 is a leap year (divisible by 4)
      assert DateUtils.valid?(:yymmdd, "240229")
    end

    test "returns false for an invalid day (e.g., February 30th)" do
      refute DateUtils.valid?(:yymmdd, "250230")
    end

    test "returns false for an invalid month (e.g., Month 13)" do
      refute DateUtils.valid?(:yymmdd, "251301")
    end

    test "returns false for a non-leap day in a non-leap year (e.g., 2025-02-29)" do
      # 2025 is not a leap year
      refute DateUtils.valid?(:yymmdd, "250229")
    end

    test "returns false for input shorter than 6 characters" do
      refute DateUtils.valid?(:yymmdd, "25123")
    end

    test "returns false for input longer than 6 characters" do
      refute DateUtils.valid?(:yymmdd, "2512310")
    end

    test "returns false for non-date string" do
      refute DateUtils.valid?(:yymmdd, "abcdef")
    end
  end

  test "valid?/2 with :yymmd0 format behaves as an alias for :yymmdd" do
    # valid
    assert DateUtils.valid?(:yymmd0, "251231")
    # invalid
    refute DateUtils.valid?(:yymmd0, "250230")
    # invalid len
    refute DateUtils.valid?(:yymmd0, "25123")
  end

  describe "to_date/2 with :yymmdd format" do
    test "successfully converts a valid date string to a Date.t()" do
      expected_date = ~D[2025-12-31]
      assert DateUtils.to_date(:yymmdd, "251231") == {:ok, expected_date}
    end

    test "handles the 2000 boundary correctly" do
      expected_date = ~D[2000-01-01]
      assert DateUtils.to_date(:yymmdd, "000101") == {:ok, expected_date}
    end

    test "converts a valid leap day (2024-02-29)" do
      expected_date = ~D[2024-02-29]
      assert DateUtils.to_date(:yymmdd, "240229") == {:ok, expected_date}
    end

    test "returns error for an invalid calendar date (e.g., February 30th)" do
      assert DateUtils.to_date(:yymmdd, "250230") == {:error, :invalid_date}
    end

    test "returns generic error for input shorter than 6 characters" do
      assert DateUtils.to_date(:yymmdd, "25123") == {:error, :invalid_date}
    end

    test "returns generic error for input longer than 6 characters" do
      assert DateUtils.to_date(:yymmdd, "2512310") == {:error, :invalid_date}
    end

    test "returns error for non-date string that matches length (e.g., invalid characters)" do
      assert DateUtils.to_date(:yymmdd, "AABBCC") == {:error, :invalid_format}
    end
  end

  test "to_date/2 with :yymmd0 format behaves as an alias for :yymmdd" do
    assert DateUtils.to_date(:yymmd0, "251231") == {:ok, ~D[2025-12-31]}
    assert DateUtils.to_date(:yymmd0, "250230") == {:error, :invalid_date}
  end
end
