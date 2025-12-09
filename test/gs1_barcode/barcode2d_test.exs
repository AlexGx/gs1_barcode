defmodule GS1.Barcode2DTest do
  use ExUnit.Case, async: true

  alias GS1.Barcode2D

  @ai_data [{"01", "12345678901234"}, {"17", "251231"}]
  @prefix "]d2"
  @content @prefix <> "011234567890123417251231"
  @barcode_type :gs1_datamatrix

  setup do
    barcode =
      Barcode2D.new(@content, @barcode_type, @prefix, @ai_data)

    {:ok, barcode: barcode}
  end

  describe "basic" do
    test "new/4 creates a struct with correct data and normalizes keyword list", %{
      barcode: barcode
    } do
      assert barcode.content == @content
      assert barcode.type == @barcode_type
      assert barcode.fnc1_prefix == @prefix
      # check that the keyword list input (that produces parser) was converted to a map
      assert barcode.ais == %{"01" => "12345678901234", "17" => "251231"}
    end
  end

  describe "accessor tests" do
    test "content/1 returns the full content", %{barcode: barcode} do
      assert Barcode2D.content(barcode) == @content
    end

    test "type/1 returns the barcode type", %{barcode: barcode} do
      assert Barcode2D.type(barcode) == @barcode_type
    end

    test "ais/1 returns the AI map", %{barcode: barcode} do
      assert Barcode2D.ais(barcode) == %{"01" => "12345678901234", "17" => "251231"}
    end

    test "fnc1_prefix/1 returns the prefix", %{barcode: barcode} do
      assert Barcode2D.fnc1_prefix(barcode) == @prefix
    end
  end

  describe "utility defs" do
    test "has_ai?/2 returns true for existing AI", %{barcode: barcode} do
      assert Barcode2D.has_ai?(barcode, "01")
    end

    test "has_ai?/2 returns false for non-existing AI", %{barcode: barcode} do
      refute Barcode2D.has_ai?(barcode, "10")
    end

    test "ai/2 returns the value for an existing AI", %{barcode: barcode} do
      assert Barcode2D.ai(barcode, "17") == "251231"
    end

    test "ai/2 returns nil for a non-existing AI", %{barcode: barcode} do
      assert is_nil(Barcode2D.ai(barcode, "10"))
    end
  end

  describe "payload tests" do
    test "payload/1 returns content without prefix when prefix is present", %{barcode: barcode} do
      assert Barcode2D.payload(barcode) == "011234567890123417251231"
    end

    test "payload/1 returns full content when prefix is empty (<<>>)" do
      no_prefix_content = "011234567890123417251231"
      barcode = Barcode2D.new(no_prefix_content, :unknown, <<>>, [])
      assert Barcode2D.payload(barcode) == no_prefix_content
    end
  end
end
