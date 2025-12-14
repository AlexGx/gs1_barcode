defmodule GS1.DateUtils do
  @moduledoc """
  Utilities for handling date formats specified by GS1.

  See: 7.12 Determination of century in dates
  """

  # Note from genspec:
  # If only year and month are available, DD must be filled with two zeroes, except where noted.

  @type date_format :: :yymmdd | :yymmd0

  @doc """
  Checks if a 6-char string is a valid date in the GS1 `YYMMDD` format.

  ## Examples

      iex> GS1.DateUtils.valid?(:yymmdd, "251231")
      true

      iex> GS1.DateUtils.valid?(:yymmdd, "250230") # invalid (feb 30)
      false

      iex> GS1.DateUtils.valid?(:yymmdd, "25123") # Invalid length
      false
  """
  @spec valid?(date_format(), String.t()) :: boolean()
  def valid?(:yymmdd, <<yy::binary-2, mm::binary-2, dd::binary-2>>) do
    case Integer.parse(yy) do
      {yy_int, ""} ->
        yyyy = yy_comp(yy_int)
        match?({:ok, _}, Date.from_iso8601("#{yyyy}-#{mm}-#{dd}"))

      _ ->
        false
    end
  end

  # according genspec: if only year and month are available, DD must be filled with two zeroes
  # threat this as fist day and validate as `:yymmdd`
  def valid?(:yymmd0, <<yy::binary-2, mm::binary-2, "00">>) do
    valid?(:yymmdd, yy <> mm <> "01")
  end

  def valid?(:yymmd0, bin), do: valid?(:yymmdd, bin)

  def valid?(:yymmdd, _), do: false

  @doc """
  Converts a 6-char GS1 date string (`YYMMDD`) into a `Date.t()`.

  ## Examples

      iex> GS1.DateUtils.to_date(:yymmdd, "251231")
      {:ok, ~D[2025-12-31]}

      iex> GS1.DateUtils.to_date(:yymmdd, "250230")
      {:error, :invalid_date}
  """
  @spec to_date(date_format(), String.t()) :: {:ok, Date.t()} | {:error, term()}
  def to_date(:yymmdd, <<yy::binary-2, mm::binary-2, dd::binary-2>>) do
    case Integer.parse(yy) do
      {yy_int, ""} ->
        yyyy = yy_comp(yy_int)
        Date.from_iso8601("#{yyyy}-#{mm}-#{dd}")

      _ ->
        {:error, :invalid_format}
    end
  end

  def to_date(:yymmdd, _), do: {:error, :invalid_date}

  def to_date(:yymmd0, bin) do
    to_date(:yymmdd, bin)
  end

  # Private section

  # year compensation according genspec: 7.12 Determination century in dates
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
