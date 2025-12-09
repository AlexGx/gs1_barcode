defmodule GS1.RulesExample do
  @moduledoc false

  alias GS1.ValidatorConfig

  import GS1.Validator.Constraint

  def validator_config do
    %ValidatorConfig{
      required_ais: ["01", "17", "10"],
      # forbidden_ais: [],
      # fail_fast: true,
      constraints: %{
        # Lot Number (10): Alphanumeric (regex) AND max 20 chars
        # (GS1 Spec says AI 10 is up to 20 alphanumeric chars)
        "10" => all(matches(~r/^[A-Za-z0-9]+$/), max_len(20)),

        # Expiration (17): Must be YYMMDD format
        # "17" => format(:date_yymmdd),

        # Count (30): Must be integer AND between 1 and 1000
        "30" => all(is_integer(), between(1, 1000)),

        # AI (99): Either 4 digits OR 6 digits (illustrating 'any')
        "99" => any(len(4), len(6))
      }
    }
  end
end
