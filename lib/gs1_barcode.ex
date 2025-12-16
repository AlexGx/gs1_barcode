defmodule GS1 do
  @moduledoc """
  Feature-rich GS1 barcode lib for Elixir.

  This module serves as a **namespace** for the lib. It does not contain business logic itself.
  Please refer to the specific modules below for functionality.

  ## Key Modules

  * `GS1.Code` - detect, validate, generate, convert, normalize, lookup range/country for GTIN-8,12,13,14 and SSCC-18.
  * `GS1.Parser` - parse GS1 element strings into GS1 Data Structure.
  * `GS1.DataStructure` - structured representation of parsed GS1 data.
  * `GS1.Validator` - validate GS1 Data Structure against business rules, mandatory field requirements, and cross-field dependencies.
  * `GS1.Formatter` - format GS1 Data Structures into various representations.

  ## DSL

  * `GS1.Validator.Constraint` - declarative DSL for defining custom validation rules and constraints for AIs in GS1 Data Structures.

  ## Utils

  * `GS1.Utils` - utils and helper functions.
  * `GS1.DateUtils` - parsing and validation utilities for GS1 dates.

  ## Foundation

  * `GS1.CheckDigit` - calculate and verify GS1 standard check digits.
  * `GS1.CompanyPrefix` - registry and lookup functions for GS1 Company Prefix ranges.
  * `GS1.AIRegistry` - registry of all Application Identifiers.
  * `GS1.FNC1Prefix` - handling of FNC1 symbology identifiers and prefix detection (GS1-128, DataMatrix, and QR Code).
  * `GS1.Consts` - GS1-specific constants and definitions.
  * `GS1.Tokenizer` - NimbleParsec-based tokenizer for low-level tokenization of GS1 element strings.

  """
end
