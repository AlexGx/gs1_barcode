defmodule GS1.ValidatorConfigTest do
  use ExUnit.Case, async: true

  doctest GS1.ValidatorConfig

  alias GS1.ValidatorConfig

  describe "builder test" do
    test "chains multiple configuration options" do
      config =
        ValidatorConfig.new()
        |> ValidatorConfig.set_fail_fast(false)
        |> ValidatorConfig.put_required_ai("01")
        |> ValidatorConfig.put_forbidden_ai("99")

      assert config.fail_fast == false
      assert "01" in config.required_ais
      assert "99" in config.forbidden_ais
    end

    test "puts constraints correctly" do
      check_fn = fn _ -> true end

      config =
        ValidatorConfig.new()
        |> ValidatorConfig.put_constraint("10", check_fn)

      assert Map.get(config.constraints, "10") == check_fn
    end

    test "set constraints" do
      check_fn = fn _ -> true end

      config =
        ValidatorConfig.new()
        |> ValidatorConfig.set_constraints(%{"10" => check_fn, "21" => check_fn})

      assert Map.get(config.constraints, "10") == check_fn
      assert Map.get(config.constraints, "21") == check_fn
    end

    test "set forbidden_ais" do
      config =
        ValidatorConfig.new()
        |> ValidatorConfig.set_forbidden_ais(["01", "17"])

      assert "01" in config.forbidden_ais
      assert "17" in config.forbidden_ais
    end

    test "set_required_ais" do
      config =
        ValidatorConfig.new()
        |> ValidatorConfig.set_required_ais(["01", "21"])

      assert "01" in config.required_ais
      assert "21" in config.required_ais
    end
  end
end
