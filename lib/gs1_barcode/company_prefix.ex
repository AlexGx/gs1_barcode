defmodule GS1.CompanyPrefix do
  @moduledoc """
  Provides range-based lookup of GS1 Company Prefix allocations in order to
  *associate* a barcode prefix with the GS1 Member Organization (MO) that
  administers the corresponding prefix range.

  This association may be used as an informational hint about the country
  in which the GS1 Company Prefix was issued, but it is **not** a structural
  property of the barcode and **must not** be interpreted as the country of
  origin of the product.

  The dataset is based on the public information from:
  [GS1 List of Assigned Country Codes](https://en.wikipedia.org/wiki/List_of_GS1_country_codes),
  [GS1 Company Prefix](https://www.gs1.org/standards/id-keys/company-prefix),
  and other public sources.
  """

  @typedoc """
  Single country's meta tuple: `{Country Name, ISO Alpha-2, ISO Alpha-3, ISO Numeric}`
  """
  @type country_info :: {String.t(), String.t(), String.t(), String.t()}

  @typedoc """
  Returns a list with countries (usually one elem) assigned to country code or `nil` if no match.
  """
  @type lookup_result :: {:ok, [country_info()]} | {:error, term()}

  @usa {"USA", "US", "USA", "840"}
  @japan {"Japan", "JP", "JPN", "392"}
  @china {"China", "CN", "CHN", "156"}
  @poland {"Poland", "PL", "POL", "616"}
  @uk {"United Kingdom", "GB", "GBR", "826"}

  @country_codes [
    {{001, 019}, [@usa]},
    # United States drugs
    {{030, 039}, [@usa]},
    # GS1 US reserved for future use
    {{050, 059}, [@usa]},
    {{060, 099}, [@usa]},
    {{100, 139}, [@usa]},
    {{300, 379}, [{"France", "FR", "FRA", "250"}]},
    {{380}, [{"Bulgaria", "BG", "BGR", "100"}]},
    {{383}, [{"Slovenia", "SI", "SVN", "705"}]},
    {{385}, [{"Croatia", "HR", "HRV", "191"}]},
    {{387}, [{"Bosnia and Herzegovina", "BA", "BIH", "070"}]},
    {{389}, [{"Montenegro", "ME", "MNE", "499"}]},
    # user-assigned / temporary code
    {{390}, [{"Kosovo", "XK", "XKX", "983"}]},
    {{400, 440}, [{"Germany", "DE", "DEU", "276"}]},
    {{450, 459}, [@japan]},
    {{460, 469}, [{"Russia", "RU", "RUS", "643"}]},
    {{470}, [{"Kyrgyzstan", "KG", "KGZ", "417"}]},
    {{471}, [{"Taiwan", "TW", "TWN", "158"}]},
    {{474}, [{"Estonia", "EE", "EST", "233"}]},
    {{475}, [{"Latvia", "LV", "LVA", "428"}]},
    {{476}, [{"Azerbaijan", "AZ", "AZE", "031"}]},
    {{477}, [{"Lithuania", "LT", "LTU", "440"}]},
    {{478}, [{"Uzbekistan", "UZ", "UZB", "860"}]},
    {{479}, [{"Sri Lanka", "LK", "LKA", "144"}]},
    {{480}, [{"Philippines", "PH", "PHL", "608"}]},
    {{481}, [{"Belarus", "BY", "BLR", "112"}]},
    {{482}, [{"Ukraine", "UA", "UKR", "804"}]},
    {{483}, [{"Turkmenistan", "TM", "TKM", "795"}]},
    {{484}, [{"Moldova", "MD", "MDA", "498"}]},
    {{485}, [{"Armenia", "AM", "ARM", "051"}]},
    {{486}, [{"Georgia", "GE", "GEO", "268"}]},
    {{487}, [{"Kazakhstan", "KZ", "KAZ", "398"}]},
    {{488}, [{"Tajikistan", "TJ", "TJK", "762"}]},
    {{489}, [{"Hong Kong", "HK", "HKG", "344"}]},
    # original Japanese Article Number range
    {{490, 499}, [@japan]},
    {{500, 509}, [@uk]},
    {{520, 521}, [{"Greece", "GR", "GRC", "300"}]},
    {{528}, [{"Lebanon", "LB", "LBN", "422"}]},
    {{529}, [{"Cyprus", "CY", "CYP", "196"}]},
    {{530}, [{"Albania", "AL", "ALB", "008"}]},
    {{531}, [{"North Macedonia", "MK", "MKD", "807"}]},
    {{535}, [{"Malta", "MT", "MLT", "470"}]},
    {{539}, [{"Ireland", "IE", "IRL", "372"}]},
    {{540, 549}, [{"Belgium", "BE", "BEL", "056"}, {"Luxembourg", "LU", "LUX", "442"}]},
    {{560}, [{"Portugal", "PT", "PRT", "620"}]},
    {{569}, [{"Iceland", "IS", "ISL", "352"}]},
    {{570, 579},
     [
       {"Denmark", "DK", "DNK", "208"},
       {"Faroe Islands", "FO", "FRO", "234"},
       {"Greenland", "GL", "GRL", "304"}
     ]},
    {{590}, [@poland]},
    {{594}, [{"Romania", "RO", "ROU", "642"}]},
    {{599}, [{"Hungary", "HU", "HUN", "348"}]},
    {{600, 601}, [{"South Africa", "ZA", "ZAF", "710"}]},
    {{603}, [{"Ghana", "GH", "GHA", "288"}]},
    {{604}, [{"Senegal", "SN", "SEN", "686"}]},
    {{605}, [{"Uganda", "UG", "UGA", "800"}]},
    {{606}, [{"Angola", "AO", "AGO", "024"}]},
    {{607}, [{"Oman", "OM", "OMN", "512"}]},
    {{608}, [{"Bahrain", "BH", "BHR", "048"}]},
    {{609}, [{"Mauritius", "MU", "MUS", "480"}]},
    {{611}, [{"Morocco", "MA", "MAR", "504"}]},
    {{612}, [{"Somalia", "SO", "SOM", "706"}]},
    {{613}, [{"Algeria", "DZ", "DZA", "012"}]},
    {{615}, [{"Nigeria", "NG", "NGA", "566"}]},
    {{616}, [{"Kenya", "KE", "KEN", "404"}]},
    {{617}, [{"Cameroon", "CM", "CMR", "120"}]},
    # Ivory Coast
    {{618}, [{"Cote d'Ivoire", "CI", "CIV", "384"}]},
    {{619}, [{"Tunisia", "TN", "TUN", "788"}]},
    {{620}, [{"Tanzania", "TZ", "TZA", "834"}]},
    {{621}, [{"Syria", "SY", "SYR", "760"}]},
    {{622}, [{"Egypt", "EG", "EGY", "818"}]},
    # Managed by GS1 Global Office for future MO" (was  Brunei until May 2021)
    {{623}, [{"Brunei", "BN", "BRN", "096"}]},
    {{624}, [{"Libya", "LY", "LBY", "434"}]},
    {{625}, [{"Jordan", "JO", "JOR", "400"}]},
    {{626}, [{"Iran", "IR", "IRN", "364"}]},
    {{627}, [{"Kuwait", "KW", "KWT", "414"}]},
    {{628}, [{"Saudi Arabia", "SA", "SAU", "682"}]},
    {{629}, [{"United Arab Emirates", "AE", "ARE", "784"}]},
    {{630}, [{"Qatar", "QA", "QAT", "634"}]},
    {{631}, [{"Namibia", "NA", "NAM", "516"}]},
    {{632}, [{"Rwanda", "RW", "RWA", "646"}]},
    {{640, 649}, [{"Finland", "FI", "FIN", "246"}]},
    {{680, 681}, [@china]},
    {{690, 699}, [@china]},
    {{700, 709}, [{"Norway", "NO", "NOR", "578"}]},
    {{729}, [{"Israel", "IL", "ISR", "376"}]},
    {{730, 739}, [{"Sweden", "SE", "SWE", "752"}]},
    {{740}, [{"Guatemala", "GT", "GTM", "320"}]},
    {{741}, [{"El Salvador", "SV", "SLV", "222"}]},
    {{742}, [{"Honduras", "HN", "HND", "340"}]},
    {{743}, [{"Nicaragua", "NI", "NIC", "558"}]},
    {{744}, [{"Costa Rica", "CR", "CRI", "188"}]},
    {{745}, [{"Panama", "PA", "PAN", "591"}]},
    {{746}, [{"Dominican Republic", "DO", "DOM", "214"}]},
    {{750}, [{"Mexico", "MX", "MEX", "484"}]},
    {{754, 755}, [{"Canada", "CA", "CAN", "124"}]},
    {{759}, [{"Venezuela", "VE", "VEN", "862"}]},
    {{760, 769}, [{"Switzerland", "CH", "CHE", "756"}, {"Liechtenstein", "LI", "LIE", "438"}]},
    {{770, 771}, [{"Colombia", "CO", "COL", "170"}]},
    {{773}, [{"Uruguay", "UY", "URY", "858"}]},
    {{775}, [{"Peru", "PE", "PER", "604"}]},
    {{777}, [{"Bolivia", "BO", "BOL", "068"}]},
    {{778, 779}, [{"Argentina", "AR", "ARG", "032"}]},
    {{780}, [{"Chile", "CL", "CHL", "152"}]},
    {{784}, [{"Paraguay", "PY", "PRY", "600"}]},
    {{786}, [{"Ecuador", "EC", "ECU", "218"}]},
    {{789, 790}, [{"Brazil", "BR", "BRA", "076"}]},
    {{800, 839}, [{"Italy", "IT", "ITA", "380"}, {"San Marino", "SM", "SMR", "674"}]},
    {{840, 849}, [{"Spain", "ES", "ESP", "724"}, {"Andorra", "AD", "AND", "020"}]},
    {{850}, [{"Cuba", "CU", "CUB", "192"}]},
    {{858}, [{"Slovakia", "SK", "SVK", "703"}]},
    {{859}, [{"Czech Republic", "CZ", "CZE", "203"}]},
    {{860}, [{"Serbia", "RS", "SRB", "688"}]},
    {{865}, [{"Mongolia", "MN", "MNG", "496"}]},
    {{867}, [{"North Korea", "KP", "PRK", "408"}]},
    {{868, 869}, [{"Turkey", "TR", "TUR", "792"}]},
    {{870, 879}, [{"Netherlands", "NL", "NLD", "528"}]},
    {{880, 881}, [{"South Korea", "KR", "KOR", "410"}]},
    {{883}, [{"Myanmar", "MM", "MMR", "104"}]},
    {{884}, [{"Cambodia", "KH", "KHM", "116"}]},
    {{885}, [{"Thailand", "TH", "THA", "764"}]},
    {{888}, [{"Singapore", "SG", "SGP", "702"}]},
    {{890}, [{"India", "IN", "IND", "356"}]},
    {{893}, [{"Vietnam", "VN", "VNM", "704"}]},
    {{894}, [{"Bangladesh", "BD", "BGD", "050"}]},
    {{896}, [{"Pakistan", "PK", "PAK", "586"}]},
    {{899}, [{"Indonesia", "ID", "IDN", "360"}]},
    {{900, 919}, [{"Austria", "AT", "AUT", "040"}]},
    {{930, 939}, [{"Australia", "AU", "AUS", "036"}]},
    {{940, 949}, [{"New Zealand", "NZ", "NZL", "554"}]},
    {{955}, [{"Malaysia", "MY", "MYS", "458"}]},
    {{958}, [{"Macao", "MO", "MAC", "446"}]}
  ]

  # special cases for gtin13?
  # 00001 – 00009
  # 0001 – 0009

  # 1.4.3 GS1-8 Prefix

  # 20000028 2000000-2990000

  # For 12-digit GTINs, and only 12-digit GTINs, there is an implied leading zero.
  # For example, given the 12-digit GTIN 614141234561, the GS1 Prefix is 061, not 614.

  @spec lookup(pos_integer()) :: lookup_result()
  def lookup(code) when is_integer(code) do
    case lookup_int(code) do
      nil -> {:error, :not_found}
      found -> {:ok, found}
    end
  end

  def lookup(_), do: {:error, :invalid}

  # Private section

  for {range_or_single, info} <- @country_codes do
    escaped_info = Macro.escape(info)

    case range_or_single do
      # range {min, max} is `in min..max` guard
      {min, max} ->
        defp lookup_int(country_code) when country_code in unquote(min)..unquote(max) do
          unquote(escaped_info)
        end

      # single int {val} is pattern match
      {single} ->
        defp lookup_int(unquote(single)) do
          unquote(escaped_info)
        end
    end
  end

  defp lookup_int(_), do: nil
end
