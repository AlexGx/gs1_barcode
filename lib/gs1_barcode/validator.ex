defmodule GS1.Validator do
  @moduledoc """
  GS1 Data Structure validator.

  Configurable validator for GS1 Data Structures with support of custom DSL constraints.
  """

  alias GS1.AIRegistry
  alias GS1.CheckDigit
  alias GS1.DataStructure
  alias GS1.DateUtils
  alias GS1.ValidationError
  alias GS1.ValidatorConfig

  @typedoc """
  Result of a validation:
  * `:ok` - signifies that Data Structure passed all validation checks.
  * `{:invalid, errors}` - when one or more validation checks failed,
  where `errors` is a list of accumulated `GS1.ValidationError.t()`.
  """
  @type result :: :ok | {:invalid, [ValidationError.t()]}

  @doc """
  Validates a GS1 Data Structure against a given configuration.

  The validation process is a pipeline of checks: required AIs, forbidden AIs,
  check digits, dates for predefined set of AIs, and custom DSL constraints.

  ## Examples
      iex> ds = %GS1.DataStructure{
      ...>  content: "01937123456789043103001234911A2B3C4D5E",
      ...>  type: :unknown,
      ...>  fnc1_prefix: "",
      ...>  ais: %{"01" => "93712345678904", "3103" => "001234", "91" => "1A2B3C4D5E"}
      ...> }
      iex> GS1.Validator.validate(ds, GS1.ValidatorConfig.new(required_ais: ["01", "3103", "91"]))
      :ok
      iex> GS1.Validator.validate(ds, GS1.ValidatorConfig.new(forbidden_ais: ["3103"]))
      {:invalid,
        [
          %GS1.ValidationError{
            code: :forbidden_ai,
            ai: "3103",
            message: ~s(Forbidden AIs found: "3103")
          }
        ]}
  """
  @spec validate(DataStructure.t(), ValidatorConfig.t()) :: result()
  def validate(%DataStructure{} = ds, %ValidatorConfig{} = config) do
    errors =
      []
      |> check_required(ds, config)
      |> check_forbidden(ds, config)
      |> check_digits(ds, config)
      |> check_dates(ds, config)
      |> check_constraints(ds, config)

    case errors do
      [] -> :ok
      errors -> {:invalid, errors}
    end
  end

  # Private section

  # required routine

  # no `fail_fast` because it is first in chain
  # defp check_required([_ | _] = errors, _ds, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_required(errors, ds, %ValidatorConfig{required_ais: required_ais}) do
    missing = required_ais -- Map.keys(ds.ais)

    Enum.reduce(missing, errors, fn missing_ai, acc ->
      [
        %ValidationError{
          code: :missing_ai,
          ai: missing_ai,
          message: ~s(Missing required AI: "#{missing_ai}")
        }
        | acc
      ]
    end)
  end

  # forbidden routine

  defp check_forbidden([_ | _] = errors, _ds, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_forbidden(errors, ds, %ValidatorConfig{forbidden_ais: forbidden_ais}) do
    present_ais = Map.keys(ds.ais)
    found = Enum.filter(forbidden_ais, &(&1 in present_ais))

    Enum.reduce(found, errors, fn forbidden_ai, acc ->
      [
        %ValidationError{
          code: :forbidden_ai,
          ai: forbidden_ai,
          message: ~s(Forbidden AIs found: "#{forbidden_ai}")
        }
        | acc
      ]
    end)
  end

  # check digit routine

  defp check_digits([_ | _] = errors, _ds, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_digits(errors, ds, _config) do
    present_ais = Map.keys(ds.ais)
    checks = Enum.filter(AIRegistry.ai_check_digit(), &(&1 in present_ais))

    Enum.reduce(checks, errors, fn check_ai, acc ->
      if CheckDigit.valid?(ds.ais[check_ai]) do
        acc
      else
        [
          %ValidationError{
            code: :invalid_check_digit,
            ai: check_ai,
            message: ~s(Invalid check digit in AI: "#{check_ai}")
          }
          | acc
        ]
      end
    end)
  end

  # check date routine

  defp check_dates([_ | _] = errors, _ds, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_dates(errors, ds, _config) do
    present_ais = Map.keys(ds.ais)
    dates = Enum.filter(AIRegistry.ai_date_yymmdd(), &(&1 in present_ais))

    Enum.reduce(dates, errors, fn date_ai, acc ->
      if DateUtils.valid?(:yymmd0, ds.ais[date_ai]) do
        acc
      else
        [
          %ValidationError{
            code: :invalid_date,
            ai: date_ai,
            message: ~s(Invalid date in AI: "#{date_ai}")
          }
          | acc
        ]
      end
    end)
  end

  # constraints routine

  defp check_constraints([_ | _] = errors, _ds, %ValidatorConfig{fail_fast: true}),
    do: errors

  defp check_constraints(errors, ds, %ValidatorConfig{constraints: constraints}) do
    Enum.reduce(constraints, errors, fn {ai, fun}, acc ->
      case Map.get(ds.ais, ai) do
        nil ->
          acc

        value ->
          do_constraint(acc, value, ai, fun)
      end
    end)
  end

  defp do_constraint(acc, value, ai, fun) do
    if fun.(value) do
      acc
    else
      [
        %ValidationError{
          code: :constraint_ai,
          ai: ai,
          message: ~s(Constraint check failed in AI: "#{ai}")
        }
        | acc
      ]
    end
  end
end
