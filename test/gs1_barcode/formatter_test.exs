defmodule GS1.FormatterTest do
  use ExUnit.Case, async: true

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
end
