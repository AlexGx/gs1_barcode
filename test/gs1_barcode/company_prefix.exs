defmodule GS1.CompanyPrefixTest do
  use ExUnit.Case, async: true

  alias GS1.CompanyPrefix

  describe "temp tests" do
    test "lookup/1 tests" do
      assert {:ok, [{"Macao", "MO", "MAC", "446"}]} = CompanyPrefix.lookup(958)

      assert {:ok, [{"Switzerland", "CH", "CHE", "756"}, {"Liechtenstein", "LI", "LIE", "438"}]} =
               CompanyPrefix.lookup(760)

      assert {:error, :not_found} = CompanyPrefix.lookup(959)
    end
  end
end
