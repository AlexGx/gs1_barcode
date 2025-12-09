defmodule GS1.Validator.Constraint do
  @moduledoc """
  DSL for building GS1 AI validation predicates.

  Produces functions of shape: fn value -> boolean end.

  Includes:
      is_numeric()
      is_integer()
      len(n)
      min_len(n)
      max_len(n)
      between(min, max)
      matches(regex)
      format(:date_yymmdd)

  Combinators:
      all(a, b) = and
      any(a, b) = or
      not_(a)   = not
  """

  # Predicates

  defmacro is_numeric do
    quote do
      fn v -> is_binary(v) and v =~ ~r/^\d+$/ end
    end
  end

  defmacro is_integer do
    quote do
      fn v ->
        is_binary(v) and match?({_, ""}, Integer.parse(v))
      end
    end
  end

  defmacro len(n) when is_integer(n) and n >= 0 do
    quote do
      fn v -> is_binary(v) and String.length(v) == unquote(n) end
    end
  end

  defmacro min_len(n) when is_integer(n) and n >= 0 do
    quote do
      fn v -> is_binary(v) and String.length(v) >= unquote(n) end
    end
  end

  defmacro max_len(n) when is_integer(n) and n >= 0 do
    quote do
      fn v -> is_binary(v) and String.length(v) <= unquote(n) end
    end
  end

  defmacro between(min, max)
           when is_integer(min) and is_integer(max) and min <= max do
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

  defmacro matches(regex) do
    quote do
      fn v -> is_binary(v) and Regex.match?(unquote(regex), v) end
    end
  end

  # Format

  defmacro format(:date_yymmdd) do
    quote do
      fn v ->
        if is_binary(v) and byte_size(v) == 6 and v =~ ~r/^\d{6}$/ do
          <<yy::binary-2, mm::binary-2, dd::binary-2>> = v
          match?({:ok, _}, Date.from_iso8601("20#{yy}-#{mm}-#{dd}"))
        else
          false
        end
      end
    end
  end

  # Combinator

  defmacro not_(a) do
    quote do
      fn v -> not unquote(a).(v) end
    end
  end

  defmacro all(a, b) do
    quote do
      fn v -> unquote(a).(v) and unquote(b).(v) end
    end
  end

  defmacro any(a, b) do
    quote do
      fn v -> unquote(a).(v) or unquote(b).(v) end
    end
  end
end
