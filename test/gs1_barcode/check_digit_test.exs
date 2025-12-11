defmodule GS1.CheckDigitTest do
  use ExUnit.Case

  alias GS1.CheckDigit

  describe "valid?/1 with standard GS1 formats" do
    test "validates GTIN-8 (Even length, starts weight 3)" do
      assert CheckDigit.valid?("05000210")
      assert CheckDigit.valid?("96385074")
    end

    test "validates GTIN-12 / UPC-A (Even length, starts weight 3)" do
      assert CheckDigit.valid?("036000291452")
      assert CheckDigit.valid?("639382000393")
    end

    test "validates GTIN-13 / EAN-13 (Odd length, starts weight 1)" do
      # standard international Codes
      assert CheckDigit.valid?("4006381333931")
      assert CheckDigit.valid?("9780471117094")
    end

    test "validates GTIN-14 (Even length, starts weight 3)" do
      # shipping container codes
      assert CheckDigit.valid?("10012345678902")
    end

    test "validates SSCC (18 digits - Even length, starts weight 3)" do
      # logistics / pallet codes
      assert CheckDigit.valid?("000000000000000017")
      assert CheckDigit.valid?("009528765123456786")
      assert CheckDigit.valid?("342603046212345678")
    end
  end

  describe "valid?/1 with invalid checksums" do
    test "rejects GTIN-8 with wrong check digit" do
      # last digit changed from 3 to 4
      refute CheckDigit.valid?("05000214")
    end

    test "rejects GTIN-13 with wrong check digit" do
      # last digit changed from 1 to 2
      refute CheckDigit.valid?("4006381333932")
    end

    test "rejects GTIN-12 with wrong check digit" do
      # last digit changed from 2 to 9
      refute CheckDigit.valid?("036000291459")
    end
  end

  describe "valid?/1 input validation and edge cases" do
    test "rejects non-digit characters" do
      # contains letter
      refute CheckDigit.valid?("400638133393A")
      # contains symbol
      refute CheckDigit.valid?("0360-0291452")
      # contains whitespace
      refute CheckDigit.valid?("036000 91452")
    end

    test "rejects non-binary inputs" do
      refute CheckDigit.valid?(12_345)
      refute CheckDigit.valid?([~c"1", ~c"2", ~c"3"])
      refute CheckDigit.valid?(nil)
      refute CheckDigit.valid?(:atom)
    end

    test "handles short strings correctly based on mod 10 math" do
      # "123": Len 3 (Odd). weights: 1, 3, 1.
      # (1*1) + (2*3) + (3*1) = 1 + 6 + 3 = 10. 10 % 10 == 0.
      # this is technically a valid Mod10 checksum, even if not a real GS1 length.
      assert CheckDigit.valid?("123")

      # "12": Len 2 (Even). W: 3, 1.
      # (1*3) + (2*1) = 3 + 2 = 5. (invalid)
      refute CheckDigit.valid?("12")
    end

    test "handles empty string" do
      refute CheckDigit.valid?("")
    end
  end

  describe "calculate/1" do
    test "calculates check digit for GTIN-8 (7 digits)" do
      assert {:ok, 4} = CheckDigit.calculate("9638507")
    end

    test "calculates check digit for GTIN-12 (11 digits)" do
      assert {:ok, 5} = CheckDigit.calculate("01234567890")
    end

    test "calculates check digit for GTIN-13 (12 digits)" do
      assert {:ok, 3} = CheckDigit.calculate("629104150021")
    end

    test "calculates check digit for GTIN-14 (13 digits)" do
      assert {:ok, 2} = CheckDigit.calculate("1001234567890")
    end

    test "calculates check digit for SSCC (17 digits)" do
      assert {:ok, 7} = CheckDigit.calculate("00000000000000001")
      assert {:ok, 6} =  CheckDigit.calculate("00952876512345678")
      assert {:ok, 8} =   CheckDigit.calculate("34260304621234567")
    end

    test "returns 0 when sum is exactly divisible by 10" do
      assert {:ok, 0} = CheckDigit.calculate("55")
    end

    test "returns error for empty string" do
      assert {:error, :empty} = CheckDigit.calculate("")
    end

    test "returns error for non-digit characters" do
      assert {:error, :non_digit} = CheckDigit.calculate("123A5")
      assert {:error, :non_digit} = CheckDigit.calculate("12-34")
      assert {:error, :non_digit} = CheckDigit.calculate("   ")
    end
  end
end
