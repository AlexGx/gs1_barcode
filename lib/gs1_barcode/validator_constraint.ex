defmodule GS1.Validator.Constraint do
  @moduledoc """
  A DSL for building reusable GS1 AI validation constraint predicates,
  that are intended to be lightweight and composable.

  ## Example

      import GS1.Validator.Constraint

      constraint = all([is_num(), len(14)])

      constraint.("12345678901234") # => true
      constraint.("ABC")            # => false
  """

  alias GS1.DateUtils
  alias DateUtils

  @type predicate :: (String.t() -> boolean())

  # Predicate primitives

  @doc "Checks if the value consists entirely of digits."
  @spec is_num() :: Macro.t()
  defmacro is_num do
    quote do
      fn v -> is_binary(v) and v =~ ~r/^\d+$/ end
    end
  end

  @doc "Checks if the value has an exact length of `n`."
  @spec len(pos_integer()) :: Macro.t()
  defmacro len(n) when is_integer(n) and n > 0 do
    quote do
      fn v -> is_binary(v) and String.length(v) == unquote(n) end
    end
  end

  @doc """
  Checks if the value has a length greater than or equal to `n`.
  """
  @spec min_len(pos_integer()) :: Macro.t()
  defmacro min_len(n) when is_integer(n) and n > 0 do
    quote do
      fn v -> is_binary(v) and String.length(v) >= unquote(n) end
    end
  end

  @doc """
  Checks if the value has a length less than or equal to `n`.
  """
  @spec max_len(pos_integer()) :: Macro.t()
  defmacro max_len(n) when is_integer(n) and n > 0 do
    quote do
      fn v -> is_binary(v) and String.length(v) <= unquote(n) end
    end
  end

  @doc """
  Checks if the value is an integer string within the range `[min, max]` (inclusive).
  """
  @spec between(pos_integer(), pos_integer()) :: Macro.t()
  defmacro between(min, max)
           when is_integer(min) and is_integer(max) and min < max do
    quote do
      fn v ->
        is_binary(v) and
          case Integer.parse(v) do
            {num, ""} -> num >= unquote(min) and num <= unquote(max)
            _ -> false
          end
      end
    end
  end

  @doc "Checks if the value matches the given Regex."
  @spec matches(Macro.t()) :: Macro.t()
  defmacro matches(regex) do
    quote bind_quoted: [regex: regex] do
      fn v -> is_binary(v) and Regex.match?(regex, v) end
    end
  end

  # Format checkers

  defmacro format(:date_yymmdd) do
    quote do
      fn v -> DateUtils.valid?(:yymmdd, v) end
    end
  end

  # Combinators

  @doc "Inverts the result of a predicate."
  @spec not_(predicate()) :: Macro.t()
  defmacro not_(a) do
    quote do
      fn v -> not unquote(a).(v) end
    end
  end

  @doc """
  Returns true only if **all** predicates in the list return true.
  Acts as a logical `AND`.

  ## Usage

      all([is_num(), len(5)])
  """
  @spec all([predicate()]) :: Macro.t()
  defmacro all(predicates) when is_list(predicates) do
    quote do
      fn v ->
        Enum.all?(unquote(predicates), fn p -> p.(v) end)
      end
    end
  end

  @doc """
  Returns true if **at least one** predicate in the list returns true.
  Acts as a logical `OR`.

  ## Usage

      any([len(5), len(8)])
  """
  @spec any([predicate()]) :: Macro.t()
  defmacro any(predicates) when is_list(predicates) do
    quote do
      fn v ->
        Enum.any?(unquote(predicates), fn p -> p.(v) end)
      end
    end
  end
end
