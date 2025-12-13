defmodule GS1.CompanyPrefixTest do
  use ExUnit.Case, async: true

  doctest GS1.CompanyPrefix

  alias GS1.CompanyPrefix

  describe "country/1" do
    test "returns correct country info for single match" do
      assert [{"Poland", "PL", "POL", "616"}] = CompanyPrefix.country(590)

      assert [{"Japan", "JP", "JPN", "392"}] = CompanyPrefix.country(450)
      assert [{"Japan", "JP", "JPN", "392"}] = CompanyPrefix.country(499)
    end

    test "returns multiple countries for shared prefixes" do
      results = CompanyPrefix.country(540)
      assert length(results) == 2
      assert {"Belgium", "BE", "BEL", "056"} in results
      assert {"Luxembourg", "LU", "LUX", "442"} in results

      # 570 is Denmark, Faroe Islands, Greenland
      results_nordic = CompanyPrefix.country(570)
      assert length(results_nordic) == 3
      assert {"Greenland", "GL", "GRL", "304"} in results_nordic
    end

    test "handles boundary conditions correctly" do
      assert [{"USA", "US", "USA", "840"}] = CompanyPrefix.country(1)
      assert [{"USA", "US", "USA", "840"}] = CompanyPrefix.country(19)

      # 020 is reserved for internal use (RCN), so it maps to no country
      assert CompanyPrefix.country(20) == nil
    end

    test "returns nil for unassigned, special range, or invalid inputs" do
      # GTIN-8 RCN range
      assert CompanyPrefix.country(000) == nil
      # ISBN (Bookland)
      assert CompanyPrefix.country(978) == nil
      # coupon
      assert CompanyPrefix.country(999) == nil
      # out of bounds
      assert CompanyPrefix.country(1234) == nil
      # invalid type
      assert CompanyPrefix.country("590") == nil
    end
  end

  describe "range/1 (Standard/GTIN-13)" do
    test "identifies standard special ranges" do
      assert :rcn == CompanyPrefix.range(20)
      assert :rcn == CompanyPrefix.range(299)
      assert :isbn == CompanyPrefix.range(978)
      assert :issn == CompanyPrefix.range(977)
      assert :coupon == CompanyPrefix.range(981)
      assert :coupon_local == CompanyPrefix.range(990)
      assert :demo == CompanyPrefix.range(952)
    end

    test "returns nil for standard country codes" do
      # 590 is Poland, not a special range
      assert CompanyPrefix.range(590) == nil
    end
  end

  describe "range8/1 (GTIN-8)" do
    test "identifies GTIN-8 specific RCN ranges" do
      # for GTIN-8, 000-099 is RCN.
      assert :rcn == CompanyPrefix.range8(0)
      assert :rcn == CompanyPrefix.range8(10)
      assert :rcn == CompanyPrefix.range8(99)
    end

    test "distinguishes between GTIN-8 and Standard logic" do
      # Prefix 010:
      # - For GTIN-12,13, this is USA (so range returns nil, it's a country)
      # - For GTIN-8, this is Restricted Circulation (RCN)
      assert is_nil(CompanyPrefix.range(10))
      assert :rcn == CompanyPrefix.range8(10)

      # Prefix 040: in both systems, this is RCN.
      assert :rcn == CompanyPrefix.range(40)
      assert :rcn == CompanyPrefix.range8(40)
    end
  end
end
