defmodule GS1.AIRegistry do
  @moduledoc """
  GS1 Application Identifier Registry.

  Provides lookup and validation mechanisms to determine the properties
  of specific AIs, such as whether they expect fixed-length data, require check
  digit validation, or represent dates (YYMMDD).
  """

  @fixed_len_ais %{
    # identification
    "00" => 20,
    "01" => 16,
    "02" => 16,
    "03" => 16,

    # dates
    "11" => 8,
    "12" => 8,
    "13" => 8,
    "15" => 8,
    "16" => 8,
    "17" => 8,

    # logistics, counts etc.
    "20" => 4,
    "31" => 10,
    "32" => 10,
    "33" => 10,
    "34" => 10,
    "35" => 10,
    "36" => 10,
    "41" => 16
  }

  @doc """
  Returns a map of Application Identifiers that have a fixed data length.

  The keys are the AI strings (e.g., "01"), and the values are the total length
  of the field (AI + Data).
  """
  @spec fixed_len_ais :: %{String.t() => pos_integer()}
  def fixed_len_ais, do: @fixed_len_ais

  @doc """
  Checks if an AI has a fixed length.
  Generated at compile-time from `@fixed_len_ais` to ensure performance.

  ## Examples

      iex> GS1.AIRegistry.fixed_len_ai?("00")
      true

      iex> GS1.AIRegistry.fixed_len_ai?("10") # Batch/Lot is variable
      false
  """
  @spec fixed_len_ai?(String.t()) :: boolean()

  for {ai, _length} <- @fixed_len_ais do
    def fixed_len_ai?(unquote(ai)), do: true
  end

  def fixed_len_ai?(_), do: false

  @ai_check_digit [
    # SSCC
    "00",
    # GTIN
    "01",
    # GTIN (contained trade items)
    "02"
  ]

  @doc """
  Returns a list of AIs whose data field must end with a standard GS1 check digit.
  """
  @spec ai_check_digit :: list(String.t())
  def ai_check_digit, do: @ai_check_digit

  @ai_date_yymmdd [
    # Prod Date
    "11",
    # Due Date
    "12",
    # Packaging Date
    "13",
    # Best Before Date
    "15",
    # Expiration Date
    "17"
  ]

  @doc """
  Returns a list of AIs whose data field is a date in `YYMMDD` format.
  """
  @spec ai_date_yymmdd :: list(String.t())
  def ai_date_yymmdd, do: @ai_date_yymmdd

  @doc """
  Determines if a given string is a valid GS1 Application Identifier.

  This checks if the string exists in the standard registry or falls within
  valid numeric ranges for 3 and 4 digit AIs.

  ## Examples

      iex> GS1.AIRegistry.compliant?("01")
      true

      iex> GS1.AIRegistry.compliant?("05")
      false
  """
  @spec compliant?(String.t()) :: boolean()
  def compliant?(ai) when is_binary(ai) do
    case byte_size(ai) do
      # "fastlane" for two digit AIs
      2 -> length_by_base_ai(ai) == 2
      3 -> ai_in_range?(ai)
      4 -> ai_in_range?(ai)
      _ -> false
    end
  end

  @doc """
  Determines the length of AI by its "base AI" representation.
  **Note:** This function is more **for internal use**.
  """
  @spec length_by_base_ai(any()) :: nil | 2 | 3 | 4

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def length_by_base_ai(<<a, b>>) do
    case <<a, b>> do
      # two digit
      "00" -> 2
      "01" -> 2
      "02" -> 2
      "03" -> 2
      "10" -> 2
      "11" -> 2
      "12" -> 2
      "13" -> 2
      "15" -> 2
      "16" -> 2
      "17" -> 2
      "20" -> 2
      "21" -> 2
      "22" -> 2
      "30" -> 2
      "37" -> 2
      "90" -> 2
      "91" -> 2
      "92" -> 2
      "93" -> 2
      "94" -> 2
      "95" -> 2
      "96" -> 2
      "97" -> 2
      "98" -> 2
      "99" -> 2
      # three digit
      "23" -> 3
      "24" -> 3
      "25" -> 3
      "40" -> 3
      "41" -> 3
      "42" -> 3
      "71" -> 3
      # four digit
      "31" -> 4
      "32" -> 4
      "33" -> 4
      "34" -> 4
      "35" -> 4
      "36" -> 4
      "39" -> 4
      "43" -> 4
      "70" -> 4
      "72" -> 4
      "80" -> 4
      "81" -> 4
      "82" -> 4
      # unknown
      _ -> nil
    end
  end

  def length_by_base_ai(_), do: nil

  @doc """
  Lookups the numeric range for 3 and 4 digit AIs.
  Returns `{min, max}` tuple if the prefix corresponds to a valid GS1 range,
  otherwise `nil`.
  """
  @spec extended_ai_range_lookup(binary()) :: {pos_integer(), pos_integer()} | nil | no_return()

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def extended_ai_range_lookup(<<a, b, c, _rest::binary>> = ai) when byte_size(ai) == 4 do
    case <<a, b, c>> do
      "310" -> {3100, 3105}
      "311" -> {3110, 3115}
      "312" -> {3120, 3125}
      "313" -> {3130, 3135}
      "314" -> {3140, 3145}
      "315" -> {3150, 3155}
      "316" -> {3160, 3165}
      "320" -> {3200, 3205}
      "321" -> {3210, 3215}
      "322" -> {3220, 3225}
      "323" -> {3230, 3235}
      "324" -> {3240, 3245}
      "325" -> {3250, 3255}
      "326" -> {3260, 3265}
      "327" -> {3270, 3275}
      "328" -> {3280, 3285}
      "329" -> {3290, 3295}
      "330" -> {3300, 3305}
      "331" -> {3310, 3315}
      "332" -> {3320, 3325}
      "333" -> {3330, 3335}
      "334" -> {3340, 3345}
      "335" -> {3350, 3355}
      "336" -> {3360, 3365}
      "337" -> {3370, 3375}
      "340" -> {3400, 3405}
      "341" -> {3410, 3415}
      "342" -> {3420, 3425}
      "343" -> {3430, 3435}
      "344" -> {3440, 3445}
      "345" -> {3450, 3455}
      "346" -> {3460, 3465}
      "347" -> {3470, 3475}
      "348" -> {3480, 3485}
      "349" -> {3490, 3495}
      "350" -> {3500, 3505}
      "351" -> {3510, 3515}
      "352" -> {3520, 3525}
      "353" -> {3530, 3535}
      "354" -> {3540, 3545}
      "355" -> {3550, 3555}
      "356" -> {3560, 3565}
      "357" -> {3570, 3575}
      "360" -> {3600, 3605}
      "361" -> {3610, 3615}
      "362" -> {3620, 3625}
      "363" -> {3630, 3635}
      "364" -> {3640, 3645}
      "365" -> {3650, 3655}
      "366" -> {3660, 3665}
      "367" -> {3670, 3675}
      "368" -> {3680, 3685}
      "369" -> {3690, 3695}
      "390" -> {3900, 3909}
      "391" -> {3910, 3919}
      "392" -> {3920, 3929}
      "393" -> {3930, 3939}
      "394" -> {3940, 3943}
      "395" -> {3950, 3955}
      "430" -> {4300, 4309}
      "431" -> {4310, 4319}
      "432" -> {4320, 4326}
      "433" -> {4330, 4333}
      "700" -> {7001, 7009}
      "701" -> {7010, 7011}
      "702" -> {7020, 7023}
      "703" -> {7030, 7039}
      "704" -> {7040, 7041}
      "723" -> {7230, 7239}
      "724" -> {7240, 7242}
      "725" -> {7250, 7259}
      "800" -> {8001, 8009}
      "801" -> {8010, 8019}
      "802" -> {8020, 8026}
      "803" -> {8030, 8030}
      "804" -> {8040, 8043}
      "811" -> {8110, 8112}
      "820" -> {8200, 8200}
      _ -> nil
    end
  end

  def extended_ai_range_lookup(<<a, b, _rest::binary>> = ai) when byte_size(ai) == 3 do
    case <<a, b>> do
      "23" -> {235, 235}
      "24" -> {240, 243}
      "25" -> {250, 255}
      "40" -> {400, 403}
      "41" -> {410, 417}
      "42" -> {420, 427}
      "71" -> {710, 717}
      _ -> nil
    end
  end

  def extended_ai_range_lookup(_), do: nil

  # Private section

  defp ai_in_range?(ai) when is_binary(ai) do
    case extended_ai_range_lookup(ai) do
      {lower, upper} ->
        int_ai = String.to_integer(ai)
        int_ai >= lower and int_ai <= upper

      nil ->
        false
    end
  end
end
