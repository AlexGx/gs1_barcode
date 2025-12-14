defmodule GS1.DateUtilsTest do
  use ExUnit.Case, async: true

  doctest GS1.DateUtils

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
      assert DateUtils.to_date(:yymmdd, "251231") == {:ok, ~D[2025-12-31]}
    end

    test "handles the 2000 boundary correctly" do
      assert DateUtils.to_date(:yymmdd, "000101") == {:ok, ~D[2000-01-01]}
    end

    test "converts a valid leap day (2024-02-29)" do
      assert DateUtils.to_date(:yymmdd, "240229") == {:ok, ~D[2024-02-29]}
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

  describe "to_date/2 with :yymmd0 format" do
    test "to_date/2 with :yymmd0 acts same as :yymmdd for non-zeroed DD" do
      assert DateUtils.to_date(:yymmdd, "240229") == DateUtils.to_date(:yymmd0, "240229")
      assert DateUtils.to_date(:yymmdd, "2512310") == DateUtils.to_date(:yymmd0, "2512310")
      assert DateUtils.to_date(:yymmdd, "161601") == DateUtils.to_date(:yymmd0, "161601")
    end

    test "to_date/2 with :yymmd0 format behaves as an alias for :yymmdd" do
      assert DateUtils.to_date(:yymmd0, "251231") == {:ok, ~D[2025-12-31]}
      assert DateUtils.to_date(:yymmd0, "250230") == {:error, :invalid_date}
    end

    test ":yymmd0 test cases from genspec" do
      assert DateUtils.to_date(:yymmd0, "130200") == {:ok, ~D[2013-02-28]}
      assert DateUtils.to_date(:yymmd0, "160200") == {:ok, ~D[2016-02-29]}
    end

    test "returns error for non-date string that matches length" do
      assert DateUtils.to_date(:yymmd0, "AABBCC") == {:error, :invalid_format}
    end

    test "more tests for coverage" do
      assert DateUtils.to_date(:yymmd0, "A10200") == {:error, :invalid_format}
      assert DateUtils.to_date(:yymmd0, "22A200") == {:error, :invalid_format}
      assert DateUtils.to_date(:yymmd0, "221300") == {:error, :invalid_date}
    end
  end
end
