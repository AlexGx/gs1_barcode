defmodule GS1.FormatterTest do
  use ExUnit.Case, async: true

  alias GS1.Consts
  alias GS1.DataStructure
  alias GS1.Formatter

  @fixture %DataStructure{
    ais: %{
      "01" => "09876543210987",
      "10" => "BATCH123",
      "17" => "251231",
      "21" => "SN999"
    }
  }

  describe "to_hri/2 defaults" do
    test "formats standard HRI sorted alphabetically by AI" do
      assert Formatter.to_hri(@fixture) ==
               "(01)09876543210987(10)BATCH123(17)251231(21)SN999"
    end

    test "handles an empty ds" do
      empty = %DataStructure{ais: %{}}
      assert Formatter.to_hri(empty) == ""
    end

    test "handles single AI" do
      single = %DataStructure{ais: %{"10" => "ABC"}}
      assert Formatter.to_hri(single) == "(10)ABC"
    end
  end

  describe "to_hri/2 options" do
    test "filters AIs using :include" do
      # only request 01 and 10, ignoring others
      assert Formatter.to_hri(@fixture, include: ["01", "10"]) ==
               "(01)09876543210987(10)BATCH123"
    end

    test "returns empty string if :include matches nothing" do
      assert Formatter.to_hri(@fixture, include: ["99"]) == ""
    end

    test "applies :before_ai prefix" do
      # prepends "AI: " before the paren
      assert Formatter.to_hri(@fixture, include: ["10"], before_ai: "AI: ") ==
               "AI: (10)BATCH123"
    end

    test "applies :after_ai suffix" do
      # adds ": " after the paren but before data
      assert Formatter.to_hri(@fixture, include: ["10"], after_ai: ": ") ==
               "(10): BATCH123"
    end

    test "joins segments using :joiner" do
      # joins with a pipe and space
      result =
        Formatter.to_hri(@fixture,
          include: ["10", "17"],
          joiner: " | "
        )

      assert result == "(10)BATCH123 | (17)251231"
    end
  end

  describe "to_hri/2 integration scenarios" do
    test "complex formatting for visual display" do
      # example: displaying nicely in a UI list
      result =
        Formatter.to_hri(@fixture,
          include: ["01", "10"],
          before_ai: "- ",
          after_ai: ": ",
          joiner: "\n"
        )

      expected = """
      - (01): 09876543210987
      - (10): BATCH123\
      """

      assert result == expected
    end

    test "ZPL-style formatting" do
      result =
        Formatter.to_hri(@fixture,
          include: ["01", "10"],
          before_ai: "^FD",
          joiner: "^FS"
        )

      assert result == "^FD(01)09876543210987^FS^FD(10)BATCH123"
    end
  end

  @gs Consts.gs_symbol()

  defp ds_mock(ais, prefix \\ "]d2") do
    %DataStructure{ais: ais, fnc1_prefix: prefix}
  end

  describe "to_gs1/2" do
    test "single fixed-length AI (e.g., 01 GTIN)" do
      # fixed length AIs never need a separator
      input = ds_mock(%{"01" => "09876543210987"})
      assert Formatter.to_gs1(input) == "]d20109876543210987"
    end

    test "single variable-length AI (e.g., 10 Batch)" do
      # even though 10 is variable, it is the last element, so no separator is added
      input = ds_mock(%{"10" => "BATCH123"})
      assert Formatter.to_gs1(input) == "]d210BATCH123"
    end

    test "sequence: Fixed (01) -> Variable (10)" do
      # 01 is fixed -> No separator
      # 10 is last -> No separator
      input = ds_mock(%{"01" => "09876543210987", "10" => "BATCH123"})

      expected = "]d2010987654321098710BATCH123"
      assert Formatter.to_gs1(input) == expected
    end

    test "sequence: Variable (10) -> Variable (21)" do
      # 10 is variable and followed by another field -> NEEDS SEPARATOR
      # 21 is last -> No separator
      input = ds_mock(%{"10" => "BATCH", "21" => "SERIAL"})

      expected = "]d2" <> "10BATCH" <> @gs <> "21SERIAL"
      assert Formatter.to_gs1(input) == expected
    end

    test "sequence: Variable (10) -> Fixed (11)" do
      # 10 is variable and followed by another field -> NEEDS SEPARATOR
      # 11 is fixed and last -> No separator
      input = ds_mock(%{"10" => "BATCH", "11" => "231231"})

      expected = "]d2" <> "10BATCH" <> @gs <> "11231231"
      assert Formatter.to_gs1(input) == expected
    end

    test "complex mixed chain: Var (10) -> Fixed (11) -> Var (21)" do
      input = ds_mock(%{"10" => "BATCH", "11" => "231231", "21" => "SN"})

      expected = "]d2" <> "10BATCH" <> @gs <> "11231231" <> "21SN"
      assert Formatter.to_gs1(input) == expected
    end

    test "handles :include option to filter AIs" do
      input = ds_mock(%{"01" => "GTIN", "10" => "BATCH", "21" => "SN"})

      # should only encode 10 and 21
      opts = [include: ["10", "21"]]

      expected = "]d2" <> "10BATCH" <> @gs <> "21SN"
      assert Formatter.to_gs1(input, opts) == expected
    end

    test "handles :prefix option" do
      input = ds_mock(%{"10" => "ABC"})
      assert Formatter.to_gs1(input, prefix: "]C1") == "]C110ABC"
    end

    test "handles :group_separator option" do
      input = ds_mock(%{"10" => "BATCH", "21" => "SN"})

      opts = [group_separator: "|"]

      assert Formatter.to_gs1(input, opts) == "]d210BATCH|21SN"
    end

    test "returns only prefix if ais map is empty" do
      assert Formatter.to_gs1(ds_mock(%{})) == "]d2"
    end
  end
end
