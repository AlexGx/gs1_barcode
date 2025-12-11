defmodule GS1.CountryCodeTest do
  use ExUnit.Case, async: true

  alias GS1.CountryCode

  describe "temp tests" do
    test "lookup/1 tests" do
      assert {:ok, [{"Macao", "MO", "MAC", "446"}]} = CountryCode.lookup(958)

      # IO.inspect(CountryCode.lookup(760))

      assert {:ok, [{"Switzerland", "CH", "CHE", "756"}, {"Liechtenstein", "LI", "LIE", "438"}]} =
               CountryCode.lookup(760)

      assert {:error, :not_found} = CountryCode.lookup(959)
    end
  end
end
