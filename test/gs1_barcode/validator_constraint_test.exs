defmodule GS1.Validator.ConstraintTest do
  use ExUnit.Case, async: true

  import GS1.Validator.Constraint

  describe "is_num/0" do
    test "returns true for numeric strings" do
      constraint = is_num()
      assert constraint.("123456")
      assert constraint.("0")
    end

    test "returns false for non-numeric characters" do
      constraint = is_num()
      refute constraint.("123a")
      refute constraint.("abc")
      refute constraint.("12.34")
      refute constraint.(" 123")
    end

    test "handles non-binary inputs safely" do
      constraint = is_num()

      refute constraint.(123)
      refute constraint.(nil)
    end
  end

  describe "len/1" do
    test "validates exact length" do
      constraint = len(3)

      assert constraint.("123")

      refute constraint.("12")
      refute constraint.("1234")
    end

    test "handles unicode graphemes correctly via String.length" do
      constraint = len(1)
      # "ä" is 1 grapheme, but 2 bytes, string len = 1
      assert constraint.("ä")
    end
  end

  describe "min_len/1 and max_len/1" do
    test "min_len verifies minimum length" do
      constraint = min_len(3)
      assert constraint.("123")
      assert constraint.("12345")
      refute constraint.("12")
    end

    test "max_len verifies maximum length" do
      constraint = max_len(3)
      assert constraint.("123")
      assert constraint.("1")
      refute constraint.("1234")
    end
  end

  describe "between/2" do
    test "validates numeric value within range inclusive" do
      constraint = between(10, 20)
      assert constraint.("10")
      assert constraint.("15")
      assert constraint.("20")
    end

    test "rejects numbers out of range" do
      constraint = between(10, 20)
      refute constraint.("9")
      refute constraint.("21")
    end

    test "rejects non-parsable strings" do
      constraint = between(1, 100)
      refute constraint.("abc")

      # Integer.parse might return {10, "abc"}, case handles this
      refute constraint.("10abc")
    end
  end

  describe "matches/1" do
    test "validates against regex" do
      constraint = matches(~r/^A\d{3}$/)

      assert constraint.("A123")

      refute constraint.("B123")
      refute constraint.("A12")
    end
  end

  describe "format(:date_yymmdd)" do
    test "validates correct YYMMDD dates" do
      constraint = format(:date_yymmdd)
      # 2023-12-31
      assert constraint.("231231")
    end

    test "rejects invalid formats (length or non-digits)" do
      constraint = format(:date_yymmdd)

      refute constraint.("23123")
      refute constraint.("2312311")
      refute constraint.("23123a")
    end

    test "validates calendar logic (months)" do
      constraint = format(:date_yymmdd)
      # month 13 is invalid
      refute constraint.("231301")
      # month 00 is invalid
      refute constraint.("230001")
    end

    test "validates calendar logic (days)" do
      constraint = format(:date_yymmdd)
      # Feb 30 is invalid
      refute constraint.("230230")
    end

    test "handles leap years correctly" do
      constraint = format(:date_yymmdd)
      # 2024 is a leap year (29 days in Feb)
      assert constraint.("240229")
      # 2023 is not a leap year
      refute constraint.("230229")
    end

    test "assumes 20xx century based on implementation" do
      constraint = format(:date_yymmdd)
      # "990101" becomes 2099-01-01 (Valid)
      assert constraint.("990101")
    end
  end

  describe "combinators" do
    test "not_ inverts result" do
      constraint = not_(len(3))

      assert constraint.("1234")

      refute constraint.("123")
    end

    test "all returns true only if all predicates pass" do
      constraint = all([is_num(), len(3)])

      assert constraint.("123")

      refute constraint.("12a")
      refute constraint.("1234")
    end

    test "any returns true if at least one predicate passes" do
      constraint = any([len(3), len(5)])
      assert constraint.("123")
      assert constraint.("12345")
      # Neither 3 nor 5
      refute constraint.("1234")
    end

    test "complex nested combinators" do
      # (is_num AND length=3) OR (~ 'magic')
      constraint =
        any([
          all([is_num(), len(3)]),
          matches(~r/^magic$/)
        ])

      assert constraint.("123")
      assert constraint.("magic")

      # fails first (not num), fails second
      refute constraint.("12a")

      # fails first (wrong len), fails second
      refute constraint.("1234")
    end
  end
end
