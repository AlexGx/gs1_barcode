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
  @sscc "012345679999999997"

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
      assert {:error, :invalid_digit_or_checksum} = Code.detect(@invalid_checksum)
    end

    test "returns error when invalid char" do
      assert {:error, :invalid_digit_or_checksum} == Code.detect(@invalid_char)
    end
  end

  describe "detect!/1 tests" do
    test "returns atom with type on success" do
      assert :gtin13 == Code.detect!("2000000000343")
    end

    test "raises ArgumentError on detect failure" do
      assert_raise ArgumentError, "invalid_length", fn ->
        Code.detect!("2000000000")
      end

      assert_raise ArgumentError, "invalid_input", fn ->
        Code.detect!(12_345)
      end
    end
  end

  describe "generate/2 tests" do
    test "generates valid GTIN-8" do
      # 1234567 -> check digit 0 -> 12345670
      assert {:ok, "12345670"} = Code.generate(:gtin8, 1_234_567)

      # Padding check: 5 -> 0000005 -> check digit ?
      {:ok, result} = Code.generate(:gtin8, 5)
      assert String.length(result) == 8
      assert String.starts_with?(result, "0000005")
    end

    test "generates valid GTIN-12" do
      # 12345678901 -> check digit 2 -> 123456789012
      assert {:ok, "123456789012"} = Code.generate(:gtin12, 12_345_678_901)

      # Padding check
      {:ok, result} = Code.generate(:gtin12, 99)
      assert String.length(result) == 12
      assert String.starts_with?(result, "00000000099")
    end

    test "generates valid GTIN-13" do
      # 200000000034 -> check digit 3 -> 2000000000343
      assert {:ok, "2000000000343"} = Code.generate(:gtin13, 200_000_000_034)

      # Padding check
      {:ok, result} = Code.generate(:gtin13, 123)
      assert String.length(result) == 13
      assert String.starts_with?(result, "000000000123")
    end

    test "returns specific error for GTIN-14" do
      assert {:error, :use_to_gtin14} = Code.generate(:gtin14, 123)
    end

    test "returns specific error for SSCC" do
      assert {:error, :use_build_sscc} = Code.generate(:sscc, 123)
    end

    test "returns error for invalid code type" do
      assert {:error, :invalid_type} = Code.generate(:isbn, 123)
      assert {:error, :invalid_type} = Code.generate(:unknown, 123)
    end

    test "returns error when key is out of bounds" do
      # GTIN-8 limit is 10_000_000 (7 digits)
      assert {:error, :key_out_of_bounds} = Code.generate(:gtin8, 10_000_000)

      # GTIN-12 limit is 100_000_000_000 (11 digits)
      assert {:error, :key_out_of_bounds} = Code.generate(:gtin12, 100_000_000_000)

      # GTIN-13 limit is 1_000_000_000_000 (12 digits)
      assert {:error, :key_out_of_bounds} = Code.generate(:gtin13, 1_000_000_000_000)
    end

    test "returns error when key is invalid (negative or zero)" do
      assert {:error, :key_out_of_bounds} = Code.generate(:gtin13, 0)
      assert {:error, :key_out_of_bounds} = Code.generate(:gtin13, -5)
    end

    test "returns error when key is not an integer" do
      assert {:error, :invalid_key} = Code.generate(:gtin13, "123")
      assert {:error, :invalid_key} = Code.generate(:gtin13, 12.5)
    end
  end

  describe "generate!/2" do
    test "returns string on success" do
      assert "2000000000343" == Code.generate!(:gtin13, 200_000_000_034)
    end

    test "raises ArgumentError on failure" do
      assert_raise ArgumentError, "use_to_gtin14", fn ->
        Code.generate!(:gtin14, 123)
      end

      assert_raise ArgumentError, "key_out_of_bounds", fn ->
        Code.generate!(:gtin8, 99_999_999)
      end

      assert_raise ArgumentError, "invalid_type", fn ->
        Code.generate!(:unknown, 123)
      end
    end
  end

  describe "to_gtin12/1 tests" do
    test "pads valid GTIN-8 to 12 digits" do
      # 40052441 -> 000040052441
      assert {:ok, "0000" <> @gtin8} = Code.to_gtin12(@gtin8)
    end

    test "fails for non-GTIN-8 inputs (cannot downcast larger codes)" do
      assert {:error, :cannot_normalize} = Code.to_gtin12(@gtin13)
    end

    test "fails for code like input" do
      assert {:error, :invalid_length} = Code.to_gtin12("")
      assert {:error, :invalid_digit_or_checksum} = Code.to_gtin12(" ffffffffffff")
    end
  end

  describe "to_gtin12!/1 tests" do
    test "normalizes GTIN-8 to GTIN-12" do
      assert Code.to_gtin12!("40052441") == "000040052441"
    end

    test "raises ArgumentError for GTIN-13" do
      assert_raise ArgumentError, "cannot_normalize", fn ->
        Code.to_gtin12!("4006381333931")
      end
    end

    test "raises ArgumentError for invalid code" do
      assert_raise ArgumentError, "invalid_length", fn ->
        Code.to_gtin12!("123")
      end
    end

    test "raises ArgumentError for invalid checksum" do
      assert_raise ArgumentError, "invalid_digit_or_checksum", fn ->
        Code.to_gtin12!("40052442")
      end
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

    test "when invalid checksum input" do
      # invalid GTIN-14
      assert {:error, :invalid_digit_or_checksum} == Code.to_gtin13("20123456789019")
      # invalid GTIN-13
      assert {:error, :invalid_digit_or_checksum} == Code.to_gtin13("0123456789019")
    end
  end

  describe "to_gtin13!/1 tests" do
    test "normalizes GTIN-8 to GTIN-13" do
      assert Code.to_gtin13!("12345670") == "0000012345670"
    end

    test "normalizes GTIN-12 to GTIN-13" do
      assert Code.to_gtin13!("012345678905") == "0012345678905"
    end

    test "returns GTIN-13 unchanged" do
      assert Code.to_gtin13!("4006381333931") == "4006381333931"
    end

    test "reduces GTIN-14 to GTIN-13" do
      assert Code.to_gtin13!("10123456789019") == "0123456789012"
    end

    test "raises ArgumentError for SSCC" do
      assert_raise ArgumentError, "cannot_normalize", fn ->
        Code.to_gtin13!("140063810000123454")
      end
    end

    test "raises ArgumentError for invalid length" do
      assert_raise ArgumentError, "invalid_length", fn ->
        Code.to_gtin13!("123")
      end
    end

    test "raises ArgumentError for invalid checksum" do
      assert_raise ArgumentError, "invalid_digit_or_checksum", fn ->
        Code.to_gtin13!("4006381333932")
      end
    end
  end

  describe "to_gtin14/2 tests" do
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

    test "when already passing gtin14" do
      assert {:error, :cannot_normalize} == Code.to_gtin14(0, "14006381333938")
      assert {:error, :cannot_normalize} == Code.to_gtin14(1, "14006381333938")
    end

    test "when invalid input (checkdigit)" do
      assert {:error, :invalid_digit_or_checksum} == Code.to_gtin14(0, "4006381333938")
      assert {:error, :invalid_digit_or_checksum} == Code.to_gtin14(1, "4006381333938")
    end

    test "build from GTIN-8 with PLI=1" do
      assert {:ok, _} = Code.to_gtin14(1, @gtin8)
    end
  end

  describe "to_gtin14!/2 tests" do
    test "converts GTIN-13 to GTIN-14 with PLI 0" do
      assert Code.to_gtin14!(0, "4006381333931") == "04006381333931"
    end

    test "converts GTIN-13 to GTIN-14 with PLI 1" do
      assert Code.to_gtin14!(1, "4006381333931") == "14006381333938"
    end

    test "converts GTIN-8 to GTIN-14 with PLI 0" do
      assert Code.to_gtin14!(0, "12345670") == "00000012345670"
    end

    test "converts GTIN-12 to GTIN-14 with PLI 0" do
      assert Code.to_gtin14!(0, "012345678905") == "00012345678905"
    end

    test "accepts PLI as char str" do
      assert Code.to_gtin14!("1", "4006381333931") == "14006381333938"
    end

    test "raises ArgumentError for SSCC" do
      assert_raise ArgumentError, "cannot_normalize", fn ->
        Code.to_gtin14!(0, "140063810000123454")
      end
    end

    test "raises ArgumentError for invalid code" do
      assert_raise ArgumentError, "invalid_length", fn ->
        Code.to_gtin14!(0, "123")
      end
    end

    test "raises ArgumentError for invalid PLI" do
      assert_raise ArgumentError, "invalid_pli", fn ->
        Code.to_gtin14!(10, "4006381333931")
      end
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

  describe "payload!/1 tests" do
    test "returns payload for GTIN-13" do
      assert Code.payload!("4006381333931") == "400638133393"
    end

    test "returns payload for GTIN-8" do
      assert Code.payload!("12345670") == "1234567"
    end

    test "returns payload for GTIN-12" do
      assert Code.payload!("012345678905") == "01234567890"
    end

    test "returns payload for GTIN-14" do
      assert Code.payload!("14006381333938") == "1400638133393"
    end

    test "returns payload for SSCC" do
      assert Code.payload!("140063810000123454") == "14006381000012345"
    end

    test "raises ArgumentError for invalid length" do
      assert_raise ArgumentError, "invalid_length", fn ->
        Code.payload!("123")
      end
    end

    test "raises ArgumentError for invalid checksum" do
      assert_raise ArgumentError, "invalid_digit_or_checksum", fn ->
        Code.payload!("4006381333932")
      end
    end

    test "raises ArgumentError for non-binary input" do
      assert_raise ArgumentError, "invalid_input", fn ->
        Code.payload!(12_345_670)
      end
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

    test "country lookup returns list/tuple for GTIN-13 and derived from him GTIN-14" do
      # assuming CompanyPrefix.country/1 returns non-nil for "400" (Germany)
      # more complex tests in `GS1.CompanyPrefixTest`
      assert nil != Code.country(@gtin13)

      assert nil != Code.country("0" <> @gtin13)

      assert Code.country(@gtin13) == Code.country("0" <> @gtin13)
    end

    test "country lookup  for SSCC" do
      assert [{"USA", "US", "USA", "840"}] == Code.country(@sscc)
    end

    test "country lookup for invalid input" do
      assert {:error, :invalid_digit_or_checksum} == Code.country("4006381333930")
    end
  end

  describe "range/1 tests" do
    test "invalid code input" do
      assert {:error, :invalid_length} == Code.range("345")
      assert {:error, :invalid_input} == Code.range(nil)
      assert {:error, :invalid_digit_or_checksum} == Code.range("4006381333930")
    end

    test "valid range inputs different cases" do
      assert {:ok, :issn} == Code.range("9771234567003")
      assert {:ok, :rcn} == Code.range("2001234567893")
    end

    test "range/1 GTIN-8 tests" do
      assert {:ok, nil} == Code.range(@gtin8)
    end
  end

  describe "build_sscc/3" do
    test "generates valid SSCC with integer extension digit" do
      assert {:ok, "140063810000123454"} = Code.build_sscc(1, "4006381", "12345")
    end

    test "test when non digit passed in gcp or serial" do
      assert {:error, :invalid} == Code.build_sscc(1, "4006381a", "12345")
      assert {:error, :invalid} == Code.build_sscc(1, "4006381", "a2345")
    end

    test "generates valid SSCC with char extension digit" do
      assert {:ok, "040063810000123457"} = Code.build_sscc(?0, "4006381", "12345")
    end

    test "pads serial number with leading zeros correctly" do
      # GCP: 123 (3 chars), Serial: 1 (1 char)
      # available: 13 chars. Padded: 0000000000001
      {:ok, sscc} = Code.build_sscc(0, "123", "1")
      assert String.length(sscc) == 18
      # 0 (ext) + 123 (gcp) + 0000000000001 (serial) + check
      assert String.starts_with?(sscc, "01230000000000001")
    end

    test "handles serial number that fits exactly without padding" do
      # GCP: 123456 (6 chars). available: 10 chars.
      # Serial: 1234567890 (10 chars).
      {:ok, sscc} = Code.build_sscc(3, "123456", "1234567890")
      assert String.length(sscc) == 18
      assert String.starts_with?(sscc, "31234561234567890")
    end

    test "returns error when serial number is too long for the GCP" do
      # GCP: 1234567890123456 (16 chars). Available: 0 chars.
      assert {:error, :gcp_or_serial_too_long} = Code.build_sscc(1, "1234567890123456", "1")

      # GCP: 123 (3 chars). Available: 13 chars. Serial: 14 chars.
      long_serial = String.duplicate("1", 14)
      assert {:error, :gcp_or_serial_too_long} = Code.build_sscc(1, "123", long_serial)
    end

    test "returns error for invalid extension digit" do
      assert {:error, :invalid} = Code.build_sscc(10, "123", "1")
      assert {:error, :invalid} = Code.build_sscc(-1, "123", "1")
      assert {:error, :invalid} = Code.build_sscc(?a, "123", "1")
    end

    test "returns error for invalid input types" do
      # GCP not binary
      assert {:error, :invalid} = Code.build_sscc(1, 123, "1")
      # Serial not binary
      assert {:error, :invalid} = Code.build_sscc(1, "123", 1)
      # ext not int/char
      assert {:error, :invalid} = Code.build_sscc("1", "123", "1")
    end
  end

  describe "build_sscc!/3" do
    test "builds valid SSCC with integer extension digit" do
      assert Code.build_sscc!(1, "4006381", "12345") == "140063810000123454"
    end

    test "builds valid SSCC with character extension digit" do
      assert Code.build_sscc!(?0, "4006381", "12345") == "040063810000123457"
    end

    test "builds SSCC with minimum serial" do
      assert Code.build_sscc!(0, "4006381", "1") == "040063810000000017"
    end

    test "builds SSCC with maximum length GCP and serial" do
      assert Code.build_sscc!(5, "1234567890123456", "") == "512345678901234565"
    end

    test "raises ArgumentError when GCP or serial too long" do
      assert_raise ArgumentError, "gcp_or_serial_too_long", fn ->
        Code.build_sscc!(1, "1234567890123456", "1")
      end
    end

    test "raises ArgumentError for invalid extension digit" do
      assert_raise ArgumentError, "invalid", fn ->
        Code.build_sscc!(10, "4006381", "12345")
      end
    end

    test "raises ArgumentError for non-numeric GCP" do
      assert_raise ArgumentError, "invalid", fn ->
        Code.build_sscc!(1, "400638X", "12345")
      end
    end
  end

  describe "to_key/1" do
    test "correctly converts GTIN-14 to base integer (strips PLI and check digit)" do
      # GTIN-14: "1" (PLI) + "123456789012" (base) + "5" (check Digit)
      assert Code.to_key("11234567890125") == {:ok, 123_456_789_012}

      # leading zeros in base number should be preserved as int value
      # "9" (PLI) + "000000000001" (base) + "9" (check digit) -> 1
      assert Code.to_key("90000000000010") == {:ok, 1}
    end

    test "correctly converts GTIN-13 to base integer (strips check digit)" do
      # GTIN-13: "123456789012" (base) + "8" (check digit)
      assert Code.to_key("1234567890128") == {:ok, 123_456_789_012}
    end

    test "correctly converts GTIN-8 to base integer (strips check digit)" do
      # GTIN-8: "1234567" (base) + "0" (check digit)
      assert Code.to_key("12345670") == {:ok, 1_234_567}
    end

    test "returns error for SSCC codes" do
      assert Code.to_key(@sscc) == {:error, :invalid_key_type}
    end

    test "propagates detection errors for invalid codes" do
      # smoke `detect/1` returns these errors for invalid inputs
      assert Code.to_key("123") == {:error, :invalid_length}
      assert Code.to_key("ABC") == {:error, :invalid_length}
      assert Code.to_key("") == {:error, :invalid_length}
    end
  end

  describe "to_key!/1" do
    test "extracts key from GTIN-13" do
      assert Code.to_key!("1234567890128") == 123_456_789_012
    end

    test "extracts key from GTIN-14 (strips PLI and check digit)" do
      assert Code.to_key!("11234567890125") == 123_456_789_012
    end

    test "extracts key from GTIN-8" do
      assert Code.to_key!("12345670") == 1_234_567
    end

    test "extracts key from GTIN-12" do
      assert Code.to_key!("012345678905") == 1_234_567_890
    end

    test "raises ArgumentError for SSCC" do
      assert_raise ArgumentError, "invalid_key_type", fn ->
        Code.to_key!("140063810000123454")
      end
    end

    test "raises ArgumentError for invalid length" do
      assert_raise ArgumentError, "invalid_length", fn ->
        Code.to_key!("123")
      end
    end

    test "raises ArgumentError for invalid checksum" do
      assert_raise ArgumentError, "invalid_digit_or_checksum", fn ->
        Code.to_key!("1234567890129")
      end
    end
  end
end
