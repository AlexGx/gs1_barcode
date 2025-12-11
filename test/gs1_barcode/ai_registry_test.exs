defmodule GS1.AIRegistryTest do
  use ExUnit.Case, async: true

  alias GS1.AIRegistry

  describe "fixed_len_ai?/1 tests" do
    test "fixed_len_ai?/1 checks" do
      assert AIRegistry.fixed_len_ai?("00")
      assert AIRegistry.fixed_len_ai?("01")
      assert AIRegistry.fixed_len_ai?("02")
      assert AIRegistry.fixed_len_ai?("03")

      assert AIRegistry.fixed_len_ai?("12")
      assert AIRegistry.fixed_len_ai?("13")
      assert AIRegistry.fixed_len_ai?("17")
      refute AIRegistry.fixed_len_ai?("99")
      refute AIRegistry.fixed_len_ai?("3105")
      refute AIRegistry.fixed_len_ai?("30")
      refute AIRegistry.fixed_len_ai?("3454")
    end
  end

  describe "fixed_len_ais/0" do
    test "returns the map of fixed length AIs" do
      ais = %{} = AIRegistry.fixed_len_ais()

      assert ais["00"] == 20
      assert ais["01"] == 16
      assert ais["20"] == 4
      assert ais["41"] == 16
    end
  end

  describe "ai_check_digit/0" do
    test "returns list of AIs requiring check digits" do
      list = AIRegistry.ai_check_digit()

      assert is_list(list)
      assert "00" in list
      assert "01" in list
      assert "02" in list
    end
  end

  describe "ai_date_yymmdd/0" do
    test "returns list of AIs with date format" do
      list = AIRegistry.ai_date_yymmdd()

      assert is_list(list)
      assert "11" in list
      assert "15" in list
      assert "17" in list
    end
  end

  describe "ai_length/1" do
    test "identifies known 2-digit AIs" do
      # Test with exact match
      assert AIRegistry.length_by_base_ai("00") == 2
      assert AIRegistry.length_by_base_ai("01") == 2
      # only "base AIs"
      assert AIRegistry.length_by_base_ai("0012345") == nil
      # test other known 2-digit prefixes
      assert AIRegistry.length_by_base_ai("10") == 2
      assert AIRegistry.length_by_base_ai("37") == 2
      assert AIRegistry.length_by_base_ai("99") == 2
    end

    test "identifies known 3-digit AIs" do
      # "23" is in the list of 3-digit prefixes
      assert AIRegistry.length_by_base_ai("23") == 3

      # but not by full
      assert AIRegistry.length_by_base_ai("235") == nil

      assert AIRegistry.length_by_base_ai("41") == 3
      assert AIRegistry.length_by_base_ai("71") == 3
    end

    test "defaults to 4-digit AIs for unknown prefixes" do
      # "80" is not in the 2 or 3 digit list
      assert AIRegistry.length_by_base_ai("80") == 4
      # but not by full
      assert AIRegistry.length_by_base_ai("8005") == nil

      refute AIRegistry.length_by_base_ai("55") == 4
    end

    test "unknown AIs" do
      assert AIRegistry.length_by_base_ai("04") == nil

      # rethink behavior ?
      # assert AIRegistry.ai_length("2351") == nil
      # assert nil == AIRegistry.ai_length("236")
    end

    test "other cases" do
      assert nil == AIRegistry.length_by_base_ai("")
      assert nil == AIRegistry.length_by_base_ai(nil)
    end
  end

  describe "extended_ai_range_lookup/1" do
    test "nil for inputs longer than 4 bytes" do
      assert is_nil(AIRegistry.extended_ai_range_lookup("12345"))
    end

    test "nil for inputs shorter than 3 bytes (1 byte)" do
      assert is_nil(AIRegistry.extended_ai_range_lookup("1"))
    end

    test "nil ArgumentError for inputs shorter than 3 bytes" do
      assert is_nil(AIRegistry.extended_ai_range_lookup("01"))
    end

    test "lookups ranges for size 4 AIs" do
      assert AIRegistry.extended_ai_range_lookup("3100") == {3100, 3105}
      assert AIRegistry.extended_ai_range_lookup("3203") == {3200, 3205}
      assert AIRegistry.extended_ai_range_lookup("3903") == {3900, 3909}
      assert AIRegistry.extended_ai_range_lookup("7034") == {7030, 7039}
      assert AIRegistry.extended_ai_range_lookup("8111") == {8110, 8112}
    end

    test "returns nil for 3-character keys not in registry" do
      assert AIRegistry.extended_ai_range_lookup("999") == nil
    end

    test "lookups ranges for 2-character keys" do
      assert AIRegistry.extended_ai_range_lookup("235") == {235, 235}
      assert AIRegistry.extended_ai_range_lookup("241") == {240, 243}
      assert AIRegistry.extended_ai_range_lookup("416") == {410, 417}
      assert AIRegistry.extended_ai_range_lookup("716") == {710, 717}
    end

    test "handles inputs with suffixes correctly based on length" do
      assert AIRegistry.extended_ai_range_lookup("310n") == {3100, 3105}
      assert AIRegistry.extended_ai_range_lookup("23X") == {235, 235}
    end
  end

  describe "compliant?/1" do
    test "two digit ais" do
      assert AIRegistry.compliant?("01")

      # non-existent
      refute AIRegistry.compliant?("05")

      # it is 3 digit
      refute AIRegistry.compliant?("23")
      # and this 4 digit
      refute AIRegistry.compliant?("70")
    end

    test "three digit ais" do
      assert AIRegistry.compliant?("235")
      refute AIRegistry.compliant?("236")

      assert AIRegistry.compliant?("427")
      refute AIRegistry.compliant?("428")
    end

    test "four digit ais" do
      assert AIRegistry.compliant?("7240")
      assert AIRegistry.compliant?("7241")
      assert AIRegistry.compliant?("7242")
      refute AIRegistry.compliant?("7243")

      refute AIRegistry.compliant?("4270")

      assert AIRegistry.compliant?("8200")
    end

    test "invalid len ais" do
      refute AIRegistry.compliant?("0")
      refute AIRegistry.compliant?("1")
      refute AIRegistry.compliant?("12345")
    end
  end
end
