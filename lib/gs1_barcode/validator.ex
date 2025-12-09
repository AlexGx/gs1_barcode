defmodule GS1.Validator do
  @moduledoc """
  GS1 2D barcode validator.
  """

  alias GS1.AIRegistry
  alias GS1.Barcode2D
  alias GS1.CheckDigit
  alias GS1.DateUtils
  alias GS1.ValidationError
  alias GS1.ValidatorConfig

  @type result :: :ok | {:invalid, [ValidationError.t()]}

  @spec validate(Barcode2D.t(), ValidatorConfig.t()) :: result()
  def validate(%Barcode2D{} = barcode, %ValidatorConfig{} = config) do
    errors =
      []
      |> check_required(barcode, config)
      |> check_forbidden(barcode, config)
      |> check_digits(barcode, config)
      |> check_dates(barcode, config)
      |> check_constraints(barcode, config)

    case errors do
      [] -> :ok
      errors -> {:invalid, errors}
    end
  end

  # required section

  # no `fail_fast` because it is first in chain
  # defp check_required([_ | _] = errors, _barcode, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_required(errors, barcode, %ValidatorConfig{required_ais: required_ais}) do
    missing = required_ais -- Map.keys(barcode.ais)

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

  # forbidden section

  defp check_forbidden([_ | _] = errors, _barcode, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_forbidden(errors, barcode, %ValidatorConfig{forbidden_ais: forbidden_ais}) do
    present_ais = Map.keys(barcode.ais)
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

  # check digit section

  defp check_digits([_ | _] = errors, _barcode, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_digits(errors, barcode, _config) do
    present_ais = Map.keys(barcode.ais)
    checks = Enum.filter(AIRegistry.ai_check_digit(), &(&1 in present_ais))

    Enum.reduce(checks, errors, fn check_ai, acc ->
      if CheckDigit.valid?(barcode.ais[check_ai]) do
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

  # check date section

  defp check_dates([_ | _] = errors, _barcode, %ValidatorConfig{fail_fast: true}), do: errors

  defp check_dates(errors, barcode, _config) do
    present_ais = Map.keys(barcode.ais)
    dates = Enum.filter(AIRegistry.ai_date_yymmdd(), &(&1 in present_ais))

    Enum.reduce(dates, errors, fn date_ai, acc ->
      if DateUtils.valid?(:yymmdd, barcode.ais[date_ai]) do
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

  # constraints section

  defp check_constraints([_ | _] = errors, _barcode, %ValidatorConfig{fail_fast: true}),
    do: errors

  defp check_constraints(errors, barcode, %ValidatorConfig{constraints: constraints}) do
    Enum.reduce(constraints, errors, fn {ai, fun}, acc ->
      case Map.get(barcode.ais, ai) do
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
