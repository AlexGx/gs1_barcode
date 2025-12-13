defmodule GS1.ValidationErrorTest do
  use ExUnit.Case, async: true

  doctest GS1.ValidationError

  alias GS1.ValidationError

  describe "struct validation" do
    test "creates a struct successfully when all enforced keys are provided" do
      error = %ValidationError{
        code: :invalid_check_digit,
        ai: "01",
        message: "Check digit invalid"
      }

      assert error.code == :invalid_check_digit
      assert error.ai == "01"
      assert error.message == "Check digit invalid"
    end

    test "raises ArgumentError if 'code' is missing" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("""
        %GS1.ValidationError{ai: "01", message: "Missing code"}
        """)
      end
    end

    test "raises ArgumentError if 'ai' is missing" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("""
        %GS1.ValidationError{code: :missing_ai, message: "Missing AI"}
        """)
      end
    end

    test "raises ArgumentError if 'message' is missing" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("""
        %GS1.ValidationError{code: :constraint_ai, ai: "10"}
        """)
      end
    end
  end

  describe "type usage" do
    test "can handle different atom codes defined in @type" do
      # This test serves as documentation that these specific atoms are valid usage
      codes = [
        :invalid_check_digit,
        :invalid_date,
        :missing_ai,
        :forbidden_ai,
        :constraint_ai
      ]

      for code <- codes do
        error = %ValidationError{code: code, ai: "00", message: "Test"}
        assert error.code == code
      end
    end
  end
end
