defmodule GS1.TokenizerTest do
  use ExUnit.Case, async: true

  doctest GS1.Tokenizer

  alias GS1.Consts
  alias GS1.Tokenizer

  @gs Consts.gs_symbol()

  describe "tokenize/1 - Fixed Length AIs" do
    test "parses a single fixed-length AI (GTIN-14)" do
      # AI "01" is fixed length (14 chars)
      input = "0109876543210987"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_fixed: {"01", "09876543210987"}
             ]
    end

    test "parses multiple fixed-length AIs without separators" do
      # AI "01" (GTIN) + AI "11" (Prod Date: YYMMDD)
      # "01" takes 14 chars, then "11" takes 6 chars immediately
      input = "010987654321098711231231"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_fixed: {"01", "09876543210987"},
               ai_fixed: {"11", "231231"}
             ]
    end

    test "fails if fixed-length AI has incomplete data" do
      # AI "01" requires 14 digits, here only 3
      input = "01123"

      assert {:error, _, _, _, _, _} = Tokenizer.tokenize(input)
    end

    test "fails if fixed-length AI contains non-numeric data" do
      # AI "01" is strictly numeric
      input = "0109876543ABCDEF"

      assert {:error, _, _, _, _, _} = Tokenizer.tokenize(input)
    end
  end

  describe "tokenize/1 - Variable Length AIs" do
    test "parses a single variable-length AI at end of string" do
      # AI "10" is Batch Number (variable).
      # since it's at eos(), no <GS> is required.
      input = "10BATCH123"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_var: {"10", "BATCH123"}
             ]
    end

    test "parses variable-length AI followed by GS and another AI" do
      # AI "10" (var) -> <GS> -> AI "21" (var) -> eos()
      input = "10BATCH" <> @gs <> "21SERIAL"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_var: {"10", "BATCH"},
               ai_var: {"21", "SERIAL"}
             ]
    end

    test "ignores the GS token in the output" do
      input = "10ABC" <> @gs

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      # <GS> is consumed but not returned in the tuple
      assert tokens == [ai_var: {"10", "ABC"}]
    end
  end

  describe "tokenize/1 - Mixed Sequences" do
    test "Fixed -> Variable (No GS required)" do
      # "01" (fixed) ends naturally. "10" (var) starts immediately.
      input = "010987654321098710BATCH"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_fixed: {"01", "09876543210987"},
               ai_var: {"10", "BATCH"}
             ]
    end

    test "Variable -> Fixed (GS required)" do
      input = "10BATCH" <> @gs <> "11231231"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_var: {"10", "BATCH"},
               ai_fixed: {"11", "231231"}
             ]
    end

    test "Complex chain: Fixed -> Var -> Var -> Fixed" do
      input = "0109876543210987" <> "10B1" <> @gs <> "21S1" <> @gs <> "11220101"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      assert tokens == [
               ai_fixed: {"01", "09876543210987"},
               ai_var: {"10", "B1"},
               ai_var: {"21", "S1"},
               ai_fixed: {"11", "220101"}
             ]
    end
  end

  describe "tokenize/1 - Edge Cases" do
    test "fails on empty string" do
      assert {:error, _, _, _, _, _} = Tokenizer.tokenize("")
    end

    test "fails if variable AI is missing GS before next segment" do
      # 10 is variable. If just concatenate 21, the tokenizer
      # will likely consume '2' and '1' as part of 10's value
      # until it hits eos() or invalid char, or fail to find a valid terminator.

      # In this specific grammar:
      # var_ai consumes `raw` chars until it hits `lookahead(gs | eos())`.
      # Since "21..." are valid raw chars, it consumes them all as part of AI "10".
      # It succeeds, but incorrectly (it sees one giant AI "10").

      input = "10BATCH21SERIAL"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)

      # The tokenizer is "dumb" - it parsed "BATCH21SERIAL" as the value for AI "10".
      # This confirms the behavior: <GS> is mandatory to separate variables.
      assert tokens == [ai_var: {"10", "BATCH21SERIAL"}]
    end

    test "handles allowed special characters in variable fields" do
      # GS1 allows characters like "%", "&", "/", etc. (Table 7.11 in spec)
      input = "10ABC/123-45"

      assert {:ok, tokens, "", _, _, _} = Tokenizer.tokenize(input)
      assert tokens == [ai_var: {"10", "ABC/123-45"}]
    end
  end
end
