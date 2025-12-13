defmodule GS1.DataStructureTest do
  use ExUnit.Case, async: true

  alias GS1.DataStructure

  doctest GS1.DataStructure

  @ai_data [{"01", "12345678901234"}, {"17", "251231"}]
  @prefix "]d2"
  @content @prefix <> "011234567890123417251231"
  @barcode_type :gs1_datamatrix

  setup do
    ds =
      DataStructure.new(@content, @barcode_type, @prefix, @ai_data)

    {:ok, ds: ds}
  end

  describe "basic" do
    test "new/4 creates a struct with correct data and normalizes keyword list", %{
      ds: ds
    } do
      assert ds.content == @content
      assert ds.type == @barcode_type
      assert ds.fnc1_prefix == @prefix
      # check that the keyword list input (that produces parser) was converted to a map
      assert ds.ais == %{"01" => "12345678901234", "17" => "251231"}
    end
  end

  describe "accessor tests" do
    test "content/1 returns the full content", %{ds: ds} do
      assert DataStructure.content(ds) == @content
    end

    test "type/1 returns the barcode type", %{ds: ds} do
      assert DataStructure.type(ds) == @barcode_type
    end

    test "ais/1 returns the AI map", %{ds: ds} do
      assert DataStructure.ais(ds) == %{"01" => "12345678901234", "17" => "251231"}
    end

    test "fnc1_prefix/1 returns the prefix", %{ds: ds} do
      assert DataStructure.fnc1_prefix(ds) == @prefix
    end
  end

  describe "utility defs" do
    test "has_ai?/2 returns true for existing AI", %{ds: ds} do
      assert DataStructure.has_ai?(ds, "01")
    end

    test "has_ai?/2 returns false for non-existing AI", %{ds: ds} do
      refute DataStructure.has_ai?(ds, "10")
    end

    test "ai/2 returns the value for an existing AI", %{ds: ds} do
      assert DataStructure.ai(ds, "17") == "251231"
    end

    test "ai/2 returns nil for a non-existing AI", %{ds: ds} do
      assert is_nil(DataStructure.ai(ds, "10"))
    end
  end

  describe "payload tests" do
    test "payload/1 returns content without prefix when prefix is present", %{ds: ds} do
      assert DataStructure.payload(ds) == "011234567890123417251231"
    end

    test "payload/1 returns full content when prefix is empty (<<>>)" do
      no_prefix_content = "011234567890123417251231"
      ds = DataStructure.new(no_prefix_content, :unknown, <<>>, [])
      assert DataStructure.payload(ds) == no_prefix_content
    end
  end
end
