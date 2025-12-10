defmodule GS1Test do
  use ExUnit.Case, async: true

  alias GS1.Parser
  alias GS1.Validator
  alias GS1.ValidatorConfig

  test "smoke" do
    {:ok, ds} = Parser.parse("]d20104600494694202215DD1gfapPai)i99ZuoK")

    config = %ValidatorConfig{required_ais: ["90"]}

    {:invalid, _errors} = Validator.validate(ds, config)

    assert true
  end

  test "another test" do
    input = "]d201106141415432191034567893145"

    {:error, {:tokenize, _, _invalid_seq_start}} = Parser.parse(input)

    # example:
    # IO.inspect(String.slice(input, invalid_seq_start..-1//1), binaries: :as_strings)

    assert true
  end
end
