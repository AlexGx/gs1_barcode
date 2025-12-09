defmodule GS1.ConstsTest do
  use ExUnit.Case, async: true

  alias GS1.Consts

  describe "gs_symbol/0" do
    test "returns the Group Separator character (ASCII 29)" do
      assert "\u001D" == Consts.gs_symbol()

      <<char_code::integer>> = Consts.gs_symbol()
      # ASCII 29 in decimal is the Group Separator (GS)
      assert char_code == 29
    end
  end

  describe "FNC1 barcode type sequences" do
    test "fnc1_gs1_datamatrix_seq returns the correct sequence" do
      assert "]d2" == Consts.fnc1_gs1_datamatrix_seq()
    end

    test "fnc1_gs1_qrcode_seq returns the correct sequence" do
      assert "]Q3" == Consts.fnc1_gs1_qrcode_seq()
    end

    test "fnc1_gs1_ean_seq returns the correct sequence" do
      assert "]e0" == Consts.fnc1_gs1_ean_seq()
    end

    test "fnc1_gs1_128_seq returns the correct sequence" do
      assert "]C1" == Consts.fnc1_gs1_128_seq()
    end
  end
end
