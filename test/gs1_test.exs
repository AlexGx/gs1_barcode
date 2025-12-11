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

  test "simple test" do
    input = "01937123456789043103001234911A2B3C4D5E"

    x = Parser.parse(input)

    # IO.inspect(x)

    # input2 = "010321234567890621A1B2C3D4E5F6G7H8"
    # input2 = "15021231"

    # remove gs for (10 max length = 20)
    # input2 = "010381234567890810ABCD1234564103898765432108" # "010381234567890810ABCD1234564103898765432108" # (01)03812345678908(10)ABCD123456(410)3898765432108
    input2 = "]d20110614141543219103456789213456789012"

    x2 = Parser.parse(input2)

    # IO.inspect(x2)

    # "010341234567890017010200"

    assert true
  end

  test "long test" do
    # (01)00012345600012(11)241007(21)S12345678(241)E003/002(3121)82(3131)67(3111)63(8013)HBD 116(90)001(91)241007-310101(92)
    # (3121)82(3131)67(3111)63(8013)HBD 116(90)001(91)241007-310101"
    input = "01000123456000121124100721S12345678241E003/00231210000828013HBD 116"

    # res = Parser.parse(input)

    # IO.inspect(res)

    assert true
  end
end
