defmodule GS1.DateUtils do
  @moduledoc """
  Utilities for handling date formats specified by GS1.

  Provides functionality to validate and convert 6-char GS1 date strings
  (in `YYMMDD` or `YYMMD0` format) into `Date.t()`.
  Includes logic for resolving the century based on the GS1 genspec
  and handling zeroed `DD` (day) fields, which signify the last day of the month.

  **GS1 GenSpec Note on Day Field (DD):**
  If only the year and month are available, the `DD` field must be filled with two zeroes ("00"),
  unless otherwise noted by the specific Application Identifier (AI).
  """

  @typedoc """
  GS1 date format specifier.

    * `:yymmdd` - standard 6-character date format requiring a specific day.
      The day field (`DD`) must be a valid day of the month (01-31) and
      cannot be zeroed ("00").

    * `:yymmd0` - extended format that additionally allows a zeroed day field ("00").
      When `DD` is "00", the date is interpreted as the last day of the specified
      month.
  """
  @type date_format :: :yymmdd | :yymmd0

  @doc """
  Checks if a 6-char string is a valid date in the GS1 `YYMMDD` (`YYMMD0`) format.

  The `:yymmdd` format **does not** allow a zeroed `DD` part ("00").
  The `:yymmd0` format **does** allow a zeroed `DD` part ("00").

  ## Examples

      iex> GS1.DateUtils.valid?(:yymmdd, "251231")
      true
      iex> GS1.DateUtils.valid?(:yymmdd, "250230") # invalid (Feb 30)
      false
      iex> GS1.DateUtils.valid?(:yymmdd, "25123") # invalid length
      false
      iex> GS1.DateUtils.valid?(:yymmdd, "250200") # :yymmdd doesn't allows zeroed `DD`
      false
      iex> GS1.DateUtils.valid?(:yymmd0, "250200") # but :yymmd0 allows zeroed `DD`
      true
  """
  @spec valid?(date_format(), String.t()) :: boolean()
  def valid?(date_format, date)

  def valid?(:yymmdd, <<yy::binary-2, mm::binary-2, dd::binary-2>>) do
    case Integer.parse(yy) do
      {yy_int, ""} ->
        year = yy_comp(yy_int)
        match?({:ok, _}, Date.from_iso8601("#{year}-#{mm}-#{dd}"))

      _ ->
        false
    end
  end

  def valid?(:yymmd0, <<yy::binary-2, mm::binary-2, "00">>) do
    # check validity using day 01, to day uses
    valid?(:yymmdd, yy <> mm <> "01")
  end

  def valid?(:yymmd0, bin), do: valid?(:yymmdd, bin)

  def valid?(:yymmdd, _), do: false

  @doc """
  Converts a 6-char GS1 date string (`YYMMDD` or `YYMMD0`) into a `Date.t()`.

  * For `:yymmdd`, the date must be a specific day.
  * For `:yymmd0`, if `DD` is "00", the resultant date is interpreted as the **last day of the month**,
      including any adjustments for leap years.

  * **GS1 GenSpec Note on Zeroed Day:**
      If the day field is "00", the date SHALL be interpreted as the last day of the noted month.
      e.g., "130200" is "2013-02-28", "160200" is "2016-02-29"

  ## Examples

      iex> GS1.DateUtils.to_date(:yymmdd, "251231")
      {:ok, ~D[2025-12-31]}
      iex> GS1.DateUtils.to_date(:yymmdd, "250230")
      {:error, :invalid_date}
      iex> GS1.DateUtils.to_date(:yymmdd, "251200")
      {:error, :invalid_date}
      iex> GS1.DateUtils.to_date(:yymmd0, "240200") # must return Feb 29 on leap year
      {:ok, ~D[2024-02-29]}
  """
  @spec to_date(date_format(), String.t()) :: {:ok, Date.t()} | {:error, term()}
  def to_date(:yymmdd, <<yy::binary-2, mm::binary-2, dd::binary-2>>) do
    case Integer.parse(yy) do
      {yy_int, ""} ->
        year = yy_comp(yy_int)
        Date.from_iso8601("#{year}-#{mm}-#{dd}")

      _ ->
        {:error, :invalid_format}
    end
  end

  # similar to `:yymmdd` but with end of month calculation
  def to_date(:yymmd0, <<yy::binary-2, mm::binary-2, "00">>) do
    case Integer.parse(yy) do
      {yy_int, ""} ->
        year = yy_comp(yy_int)

        case Integer.parse(mm) do
          {mm_int, ""} ->
            end_of_month(year, mm_int)

          _ ->
            {:error, :invalid_format}
        end

      _ ->
        {:error, :invalid_format}
    end
  end

  # bypass as `:yymmdd` when `DD` is not zeroed
  def to_date(:yymmd0, bin), do: to_date(:yymmdd, bin)

  def to_date(_, _), do: {:error, :invalid_date}

  # Private section

  # calculates the last day of the month for a given year and month.
  defp end_of_month(year, mm) do
    case Date.new(year, mm, 1) do
      {:ok, date} ->
        {:ok, Date.end_of_month(date)}

      error ->
        error
    end
  end

  # year compensation for `YY` according genspec: 7.12 Determination century in dates
  defp yy_comp(yy, curr_year \\ Date.utc_today().year)

  defp yy_comp(yy, curr_year)
       when is_integer(yy) and is_integer(curr_year) and yy >= 0 do
    curr_year_cc = div(curr_year, 100)
    curr_year_yy = rem(curr_year, 100)
    gap = yy - curr_year_yy

    century_comp =
      cond do
        gap >= 51 -> -1
        gap <= -50 -> 1
        true -> 0
      end

    (curr_year_cc + century_comp) * 100 + yy
  end

  defp yy_comp(_, _), do: nil
end
