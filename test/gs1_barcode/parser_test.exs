defmodule GS1.ParserTest do
  use ExUnit.Case, async: true

  doctest GS1.Parser

  alias GS1.DataStructure
  alias GS1.Parser

  describe "parse/1 input validation" do
    test "returns error for empty string" do
      assert Parser.parse("") == {:error, :empty}
    end

    test "success pass with long real data" do
      input =
        "01095060001343521124100721S12345678241E003/0023121820000313167000031116300009000191241007-310101"

      {:ok, result} = Parser.parse(input)

      refute Map.has_key?(result.ais, "00")
      assert Map.has_key?(result.ais, "01")

      assert Map.has_key?(result.ais, "3111")
      assert Map.has_key?(result.ais, "3131")
      assert Map.has_key?(result.ais, "90")
      assert Map.has_key?(result.ais, "91")
    end

    test "returns error for non-binary input" do
      assert Parser.parse(123) == {:error, :invalid_input}
      assert Parser.parse(nil) == {:error, :invalid_input}
    end
  end

  describe "parse/1 tokenization integration" do
    test "returns tokenize error tuple on tokenizer failure" do
      assert {:error, {:tokenize, reason, pos}} = Parser.parse("BAD_INPUT")
      assert reason == "expected variable-length AI while processing AI segment"
      assert pos == 0
    end

    test "has invalid character (space, not in GS1 aplhabet)" do
      invalid = "01000123456000121124100721S12345678241E003/00231210000828013HBD 116"

      # invalid sequence (AI "8013") start at index 58
      assert {:error, {:tokenize, "expected end of string", 58}} = Parser.parse(invalid)
    end
  end

  describe "parse/1 normalization & reconstruction" do
    test "parses fixed length AI (01) correctly" do
      # "01" is length 2 in AIRegistry, so no reconstruction needed.
      input = "]d20198765432109876"

      assert {:ok, result} = Parser.parse(input)

      assert %DataStructure{} = result
      assert result.type == :gs1_datamatrix
      assert result.fnc1_prefix == "]d2"
      assert DataStructure.has_ai?(result, "01")
      assert DataStructure.ai(result, "01") == "98765432109876"
    end

    test "reconstructs variable length AI (31xx) correctly" do
      # must take 2 chars ("02") from data, append to AI -> "3102".
      # "3102" is compliant (3100-3105 range).
      input = "3102000123"

      assert {:ok, result} = Parser.parse(input)

      # ensure "31" ("base ai") is NOT in the final map
      refute DataStructure.has_ai?(result, "31")

      # ensure "3102" (the reconstructed AI) IS IN the final map
      assert DataStructure.has_ai?(result, "3102")
      assert DataStructure.ai(result, "3102") == "000123"
    end

    test "fails if reconstructed AI is not in registry compliant range" do
      # "31" -> len 4. Takes "09" -> AI "3109".
      # extended_ai_range_lookup("310") -> {3100, 3105}.
      # 3109 is > 3105, so `compliant?/1` returns false.
      input = "3109000123"

      assert {:error, {:unknown_ai, {ai, _data}}} = Parser.parse(input)
      assert ai == "3109"
    end

    # this test cases not happens because it caught on tokenize stage

    # test "fails if suffix for reconstruction is non-numeric" do
    #   input = "31XX000123"

    #   assert {:error, {:ai_part_non_num, {ai, data}}} = Parser.parse(input)
    #   assert ai == "31"
    #   assert data == "XX000123"
    # end

    # test "fails if there is not enough data for reconstruction" do
    #   # registry "31" wants 4 digits total (2 base + 2 suffix).
    #   # "base ai" is "31", need 2 chars from data. Data is only "0" (1 char).
    #   input = "31XXX"

    #   assert {:error, {:not_enough_data, {ai, data}}} = Parser.parse(input)
    #   assert ai == "31"
    #   assert data == "0"
    # end
  end

  describe "parse/1 logic checks" do
    test "detects duplicate AIs" do
      ai = "0104600494694202"
      input = ai <> ai

      assert {:error, {:duplicate_ai, {ai, _data}}} = Parser.parse(input)
      assert ai == "01"
    end

    test "detects unknown AIs" do
      # "77" returns nil in AIRegistry.ai_length/1
      input = "7712345"

      assert {:error, {:unknown_ai, {ai, _data}}} = Parser.parse(input)
      assert ai == "77"
    end
  end

  describe "GS1-128 tests" do
    @gs1_128 "01040123456789011715012910ABC1233932978471131030005253922471142127649716"

    test "valid GS1-128 with prefix" do
      prefix = "]C1"
      input = prefix <> @gs1_128

      assert {:ok, result} = Parser.parse(input)

      assert result.type == :gs1_128
      assert result.fnc1_prefix == prefix
      assert map_size(result.ais) == 7
    end
  end

  describe "GS-1 DataMatrix tests" do
    @gs1_dm "0100730822075053173002281010738870112503072002"

    test "valid GS-1 DataMatrix with prefix" do
      prefix = "]d2"
      input = prefix <> @gs1_dm

      assert {:ok, result} = Parser.parse(input)

      assert result.type == :gs1_datamatrix
      assert result.fnc1_prefix == prefix
      assert map_size(result.ais) == 5
    end

    test "valid GS-1 DataMatrix without prefix" do
      assert {:ok, result} = Parser.parse(@gs1_dm)
      assert result.type == :unknown
      assert result.fnc1_prefix == ""
      assert map_size(result.ais) == 5
    end

    test "invalid GS-1 DataMatrix without prefix with unknown AI" do
      invalid = "010073082207505373002281010738870112503072002"
      assert {:error, {:unknown_ai, {"73", "002281010738870"}}} == Parser.parse(invalid)
    end
  end

  describe "misc / examples" do
    test "example how to get start of where tokenization failed" do
      invalid_input = "]d201106141415432191034567893145"

      assert {:error, {:tokenize, _, invalid_seq_start}} = Parser.parse(invalid_input)

      substring_where_invalid_sequence_started =
        String.slice(invalid_input, invalid_seq_start..-1//1)

      # string from failed to parse sequence to end:
      assert "3145" == substring_where_invalid_sequence_started
    end
  end
end
