defmodule GS1.ParserTest do
  use ExUnit.Case, async: true

  alias GS1.DataStructure
  alias GS1.Parser

  describe "parse/1 input validation" do
    test "returns error for empty string" do
      assert Parser.parse("") == {:error, :empty}
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
end
