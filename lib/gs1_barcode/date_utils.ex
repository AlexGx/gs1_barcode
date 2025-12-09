defmodule GS1.DateUtils do
  @moduledoc """
  Utilities for handling date formats specified by GS1,
  """

  @type gs1_format :: :yymmdd | :yymmd0

  @doc """
  Checks if a 6-character string is a valid date in the GS1 `YYMMDD` format.

  ## Examples

      iex> GS1.DateUtils.valid?(:yymmdd, "251231")
      true

      iex> GS1.DateUtils.valid?(:yymmdd, "250230") # Invalid day
      false

      iex> GS1.DateUtils.valid?(:yymmdd, "25123") # Invalid length
      false
  """
  @spec valid?(gs1_format(), String.t()) :: boolean()
  def valid?(:yymmdd, <<yy::binary-2, mm::binary-2, dd::binary-2>>) do
    match?({:ok, _}, Date.from_iso8601("20#{yy}-#{mm}-#{dd}"))
  end

  def valid?(:yymmdd, _), do: false

  def valid?(:yymmd0, bin), do: valid?(:yymmdd, bin)

  @doc """
  Converts a 6-character GS1 date string (`YYMMDD`) into an Elixir `Date.t()`.

  ## Examples

      iex> GS1.DateUtils.to_date(:yymmdd, "251231")
      {:ok, ~D[2025-12-31]}

      iex> GS1.DateUtils.to_date(:yymmdd, "250230")
      {:error, :invalid_date}
  """
  @spec to_date(gs1_format(), String.t()) :: {:ok, Date.t()} | {:error, term()}
  def to_date(:yymmdd, <<yy::binary-2, mm::binary-2, dd::binary-2>>) do
    Date.from_iso8601("20#{yy}-#{mm}-#{dd}")
  end

  def to_date(:yymmdd, _), do: {:error, :invalid_date}

  def to_date(:yymmd0, bin) do
    to_date(:yymmdd, bin)
  end
end
