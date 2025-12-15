defmodule GS1.ValidatorTest do
  use ExUnit.Case, async: true

  doctest GS1.Validator

  alias GS1.AIRegistry
  alias GS1.CheckDigit
  alias GS1.DataStructure
  alias GS1.DateUtils
  alias GS1.ValidationError
  alias GS1.Validator
  alias GS1.ValidatorConfig

  @ds_valid %DataStructure{
    content: "0193712345678904152512313103001234911A2B3C4D5E",
    type: :unknown,
    fnc1_prefix: "",
    ais: %{
      "01" => "93712345678904",
      "15" => "251231",
      "3103" => "001234",
      "91" => "1A2B3C4D5E",
      "400" => "FREE_TEXT"
    }
  }

  @ds_invalid %DataStructure{
    content: "0193712345678905152513403103001234911A2B3C4D5E",
    type: :unknown,
    fnc1_prefix: "",
    ais: %{
      # invalid GTIN-14 check digit in AI "01"
      "01" => "93712345678905",
      # invalid date (month 13 is invalid) in AI "15"
      "15" => "251320",
      "3103" => "001234",
      "91" => "1A2B3C4D5E",
      "400" => "CUST_NUM_4"
    }
  }

  @valid_config %ValidatorConfig{}

  describe "validate/2 - Full Validation Pipeline" do
    test "returns :ok when all checks pass" do
      config = %ValidatorConfig{
        # both present
        required_ais: ["01", "15"],
        # not present
        forbidden_ais: ["4000"],
        # constraint defined and passes
        constraints: %{"91" => fn _ -> true end}
      }

      # test assumes:
      # - AIRegistry.ai_check_digit() includes "01"
      # - CheckDigit.valid?("93712345678904") is true
      # - AIRegistry.ai_date_yymmdd() includes "15"
      # - DateUtils.valid?(:yymmd0, "251231") is true
      assert Validator.validate(@ds_valid, config) == :ok
    end

    test "many errors from different groups returned with `fail_fast` = false" do
      # a scenario that hits multiple failures across routines
      config = %ValidatorConfig{
        fail_fast: false,
        # "00" is missing
        required_ais: ["01", "00"],
        # "400" is present and forbidden
        forbidden_ais: ["400"],
        # constraint fails
        constraints: %{"91" => fn _ -> false end}
      }

      {:invalid, errors} = Validator.validate(@ds_invalid, config)

      # expect total 5 accumulated errors:
      # - Missing AI ("00")
      # - Forbidden AI ("400")
      # - Invalid Check Digit ("01")
      # - Invalid Date ("15")
      # - Constraint Failure ("91")
      assert length(errors) == 5

      codes = Enum.map(errors, & &1.code)
      assert :missing_ai in codes
      assert :forbidden_ai in codes
      assert :invalid_check_digit in codes
      assert :invalid_date in codes
      assert :constraint_ai in codes
    end
  end

  describe "check_required/3" do
    test "reports missing AIs" do
      config = %ValidatorConfig{required_ais: ["01", "00", "410"]}

      {:invalid, errors} = Validator.validate(@ds_valid, config)
      # sort assertion
      errors = Enum.sort_by(errors, & &1.ai)

      # must only report "00" and "410" as missing
      assert length(errors) == 2

      assert errors == [
               %ValidationError{
                 code: :missing_ai,
                 ai: "00",
                 message: ~s(Missing required AI: "00")
               },
               %ValidationError{
                 code: :missing_ai,
                 ai: "410",
                 message: ~s(Missing required AI: "410")
               }
             ]
    end
  end

  describe "check_forbidden/3" do
    test "reports forbidden AIs" do
      # "00" is not present in @ds_valid
      config = %ValidatorConfig{forbidden_ais: ["3103", "400", "00"]}

      {:invalid, errors} = Validator.validate(@ds_valid, config)
      errors = Enum.sort_by(errors, & &1.ai)

      # must only report "3103" and "400" as present and forbidden
      assert length(errors) == 2

      assert errors == [
               %ValidationError{
                 code: :forbidden_ai,
                 ai: "3103",
                 message: ~s(Forbidden AIs found: "3103")
               },
               %ValidationError{
                 code: :forbidden_ai,
                 ai: "400",
                 message: ~s(Forbidden AIs found: "400")
               }
             ]
    end
  end

  describe "check_digits/3" do
    test "reports invalid check digits for relevant AIs with `fail_fast` = false" do
      config = %ValidatorConfig{
        fail_fast: false,
        forbidden_ais: ["4000"],
        constraints: %{"91" => fn _ -> true end}
      }

      {:invalid, errors} = Validator.validate(@ds_invalid, config)

      # "01" check digit fails, "15" date check fails
      assert length(errors) == 2
      assert Enum.any?(errors, fn e -> e.code == :invalid_check_digit and e.ai == "01" end)
    end
  end

  describe "check_dates/3" do
    test "reports invalid date format for relevant AIs with `fail_fast` = false" do
      config = %ValidatorConfig{
        fail_fast: false,
        forbidden_ais: ["4000"],
        constraints: %{"91" => fn _ -> true end}
      }

      {:invalid, errors} = Validator.validate(@ds_invalid, config)

      # "01" check digit fails, "15" date check fails
      assert length(errors) == 2
      assert Enum.any?(errors, fn e -> e.code == :invalid_date and e.ai == "15" end)
    end
  end

  describe "check_constraints/3" do
    test "reports constraint failure for a present AI" do
      # constraint for "91" fails
      config = %ValidatorConfig{
        constraints: %{"91" => fn val -> val == "correct_value" end},
        forbidden_ais: ["4000"]
      }

      {:invalid, errors} = Validator.validate(@ds_valid, config)

      # check that constraint failure present
      assert Enum.any?(errors, fn e -> e.code == :constraint_ai and e.ai == "91" end)
    end

    test "passes when constraints pass" do
      config = %ValidatorConfig{
        constraints: %{"91" => fn val -> String.contains?(val, "E") end},
        forbidden_ais: ["4000"]
      }

      assert :ok == Validator.validate(@ds_valid, config)
    end

    test "skips (ignores) constraints for missing AIs" do
      # Constraint for "00" (missing) is not run, and "91" (passing)
      config = %ValidatorConfig{
        constraints: %{
          # should be ignored because "00" is missing
          "00" => fn _ -> false end,
          # should pass
          "91" => fn _ -> true end
        },
        forbidden_ais: ["4000"]
      }

      # assuming no check_digit or date validation fails for @ds_valid
      case Validator.validate(@ds_valid, config) do
        :ok ->
          assert true

        {:invalid, errors} ->
          # assert that the only errors are from check_digits/dates, not constraints
          assert Enum.all?(errors, fn e -> e.code not in [:constraint_ai] end)
      end
    end
  end
end
