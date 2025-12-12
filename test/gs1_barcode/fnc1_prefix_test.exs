defmodule GS1.FNC1PrefixTest do
  use ExUnit.Case, async: true

  alias GS1.Consts
  alias GS1.FNC1Prefix

  describe "match/1" do
    test "correctly matches GS1 DataMatrix prefix" do
      prefix = Consts.fnc1_gs1_datamatrix_seq()
      payload = "12345ABC"
      input = prefix <> payload

      assert {:gs1_datamatrix, ^prefix, ^payload} = FNC1Prefix.match(input)
    end

    test "correctly matches GS1 QRCode prefix" do
      prefix = Consts.fnc1_gs1_qrcode_seq()
      payload = "https://example.com"
      input = prefix <> payload

      assert {:gs1_qrcode, ^prefix, ^payload} = FNC1Prefix.match(input)
    end

    test "correctly matches GS1 EAN prefix" do
      prefix = Consts.fnc1_gs1_ean_seq()
      payload = "00123456789"
      input = prefix <> payload

      assert {:gs1_ean, ^prefix, ^payload} = FNC1Prefix.match(input)
    end

    test "correctly matches GS1 128 prefix" do
      prefix = Consts.fnc1_gs1_128_seq()
      payload = "some-content"
      input = prefix <> payload

      assert {:gs1_128, ^prefix, ^payload} = FNC1Prefix.match(input)
    end

    test "handles input containing ONLY the prefix (empty rest)" do
      prefix = Consts.fnc1_gs1_datamatrix_seq()

      assert {:gs1_datamatrix, ^prefix, ""} = FNC1Prefix.match(prefix)
    end

    test "returns unknown for binaries that do not match any prefix" do
      input = "NOT_A_VALID_PREFIX" <> "some data"

      assert {:unknown, "", ^input} = FNC1Prefix.match(input)
    end

    test "returns unknown for empty binaries" do
      assert {:unknown, "", ""} = FNC1Prefix.match("")
    end

    test "returns unknown for partial matches (prefix cut off)" do
      full_prefix = Consts.fnc1_gs1_datamatrix_seq()

      # Take only the first byte of the prefix to simulate a partial/incomplete scan
      partial_prefix = binary_part(full_prefix, 0, 1)

      assert {:unknown, "", ^partial_prefix} = FNC1Prefix.match(partial_prefix)
    end
  end
end
