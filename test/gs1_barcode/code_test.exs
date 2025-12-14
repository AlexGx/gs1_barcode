defmodule GS1.CodeTest do
  use ExUnit.Case, async: true

  doctest GS1.Code

  alias GS1.Code

  @gtin8 "40052441"
  @gtin12 "036000291452"
  @gtin13 "4006381333931"
  @gtin13_book "9783161484100"
  # derived from @gtin12 with PLI=1
  @gtin14 "10036000291459"
  # standard SSCC
  @sscc "000000000000000000"

  # Invalid fixtures
  @invalid_length "123"
  @invalid_checksum "4006381333930"
  @invalid_char "400638133393A"

  describe "detect/1" do
    test "identifies valid GTIN-8" do
      assert {:ok, :gtin8} = Code.detect(@gtin8)
    end

    test "identifies valid GTIN-12 (UPC-A)" do
      assert {:ok, :gtin12} = Code.detect(@gtin12)
    end

    test "identifies valid GTIN-13" do
      assert {:ok, :gtin13} = Code.detect(@gtin13)
    end

    test "identifies valid GTIN-14" do
      assert {:ok, :gtin14} = Code.detect(@gtin14)
    end

    test "identifies valid SSCC" do
      # assuming CheckDigit allows this specific SSCC, otherwise use a valid calc
      # for this test, ensure the SSCC used is valid per CheckDigit.valid?/1
      assert {:ok, :sscc} = Code.detect(@sscc)
    end

    test "returns error for invalid length" do
      assert {:error, :invalid_length} = Code.detect(@invalid_length)
    end

    test "returns error for invalid input type" do
      assert {:error, :invalid_input} = Code.detect(12_345)
    end

    test "returns error for invalid checksum" do
      assert {:error, :invalid_checksum} = Code.detect(@invalid_checksum)
    end

    test "returns error when invalid char" do
      # review
      assert {:error, :invalid_checksum} == Code.detect(@invalid_char)
    end
  end

  describe "to_gtin12/1" do
    test "pads valid GTIN-8 to 12 digits" do
      # 40052441 -> 000040052441
      assert {:ok, "0000" <> @gtin8} = Code.to_gtin12(@gtin8)
    end

    test "fails for non-GTIN-8 inputs (cannot downcast larger codes)" do
      assert {:error, :cannot_normalize} = Code.to_gtin12(@gtin13)
    end
  end

  describe "to_gtin13/1" do
    test "pads valid GTIN-8 to 13 digits" do
      assert {:ok, "00000" <> @gtin8} = Code.to_gtin13(@gtin8)
    end

    test "pads valid GTIN-12 to 13 digits" do
      assert {:ok, "0" <> @gtin12} = Code.to_gtin13(@gtin12)
    end

    test "returns valid GTIN-13 as is" do
      assert {:ok, @gtin13} = Code.to_gtin13(@gtin13)
    end

    test "normalizes GTIN-14 to GTIN-13 by stripping PLI and recalculating checksum" do
      # input: 10123456789019 (PLI 1, Payload 012345678901, Check 9)
      # expected: 012345678901 + new calculated check digit (2)
      input_gtin14 = "10123456789019"
      expected_gtin13 = "0123456789012"
      assert {:ok, expected_gtin13} == Code.to_gtin13(input_gtin14)
    end

    test "fails for SSCC (no product ID)" do
      assert {:error, :cannot_normalize} = Code.to_gtin13(@sscc)
    end
  end

  describe "to_gtin14/2" do
    test "pads with 0 (PLI 0) simply by prepending zeros" do
      # should preserve existing check digit
      assert {:ok, "0" <> @gtin13} == Code.to_gtin14(0, @gtin13)
      assert {:ok, "00" <> @gtin12} == Code.to_gtin14(0, @gtin12)
    end

    test "creates new hierarchy with PLI 1-9 and recalculates checksum" do
      assert {:ok, "14006381333938"} == Code.to_gtin14(1, @gtin13)
    end

    test "accepts string character PLI" do
      assert {:ok, "14006381333938"} == Code.to_gtin14("1", @gtin13)
    end

    test "returns error for invalid PLI" do
      assert {:error, :invalid_pli} = Code.to_gtin14(10, @gtin13)
    end
  end

  describe "payload/1" do
    test "returns digits excluding check digit" do
      assert {:ok, "400638133393"} = Code.payload(@gtin13)
    end

    test "returns error for invalid code" do
      assert {:error, :invalid_length} = Code.payload("123")
    end
  end

  describe "Metadata and Range checks" do
    test "detects RCN (Restricted Circulation Number)" do
      internal_code = "2001234567893"
      assert Code.rcn?(internal_code)
      refute Code.rcn?(@gtin13)
    end

    test "detects RCN for GTIN-12 (UPC starting with 2)" do
      # UPC-A "2..." becomes "02..." internally, which is RCN range 020-029
      upc_variable_weight = "212345678909"
      assert Code.rcn?(upc_variable_weight)
    end

    test "detects ISBN" do
      assert Code.isbn?(@gtin13_book)
      refute Code.isbn?(@gtin13)
    end

    test "detects ISSN" do
      issn_code = "9771234567003"
      assert Code.issn?(issn_code)
    end

    test "detects Coupon" do
      coupon_code = "9812345678902"
      assert Code.coupon?(coupon_code)
    end

    test "detects Refund Receipt" do
      refund_code = "9800004500008"
      assert Code.refund?(refund_code)
    end

    test "country lookup returns nil for GTIN-8" do
      assert Code.country(@gtin8) == nil
    end

    test "country lookup returns list/tuple for GTIN-13" do
      # assuming CompanyPrefix.country/1 returns non-nil for "400" (Germany)
      # more complex tests in `GS1.CompanyPrefixTest`
      assert Code.country(@gtin13) != nil
    end
  end
end
