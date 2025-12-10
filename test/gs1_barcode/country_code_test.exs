defmodule GS1.CountryCodeTest do
  use ExUnit.Case, async: true

  alias GS1.CountryCode

  describe "temp tests" do
    test "lookup/1 tests" do
      assert CountryCode.lookup(958) == [{"Macao", "MO", "MAC", "446"}]

      assert CountryCode.lookup(760) == [
               {"Switzerland", "CH", "CHE", "756"},
               {"Liechtenstein", "LI", "LIE", "438"}
             ]

      assert is_nil(CountryCode.lookup(959))
    end
  end
end
