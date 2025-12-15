defmodule GS1.ValidatorConfig do
  @moduledoc """
  GS1 Validator config struct.

  Defines the rules used to validate a parsed `t:GS1.DataStructure.t/0`.
  Supports builder style, allowing to chain configuration options.

  ## Options

    * `:fail_fast` - If `true`, validation stops when error found. Defaults to `true`.
    * `:required_ais` - list of AIs that **must** appear in the Data Structure.
    * `:forbidden_ais` - ist of AIs that **must NOT** appear.
    * `:constraints` - map of custom validation functions keyed by AI.
  """

  alias GS1.Validator.Constraint

  @type t :: %__MODULE__{
          fail_fast: boolean(),
          required_ais: [String.t()],
          forbidden_ais: [String.t()],
          constraints: %{String.t() => Constraint.predicate()}
        }

  defstruct fail_fast: true,
            required_ais: [],
            forbidden_ais: [],
            constraints: %{}

  @doc """
  Creates a new `GS1.ValidatorConfig` with optional default values.

  ## Examples

      iex> GS1.ValidatorConfig.new(fail_fast: false, required_ais: ["01", "21"])
      %GS1.ValidatorConfig{
        fail_fast: false,
        required_ais: ["01", "21"],
        forbidden_ais: [],
        constraints: %{}
      }
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    struct!(__MODULE__, opts)
  end

  @doc "Sets the `fail_fast` strategy."
  @spec set_fail_fast(t(), boolean()) :: t()
  def set_fail_fast(%__MODULE__{} = config, fail_fast) when is_boolean(fail_fast),
    do: %__MODULE__{config | fail_fast: fail_fast}

  @doc "Sets (replaces) list of required AIs."
  @spec set_required_ais(t(), list()) :: t()
  def set_required_ais(%__MODULE__{} = config, ais) when is_list(ais),
    do: %__MODULE__{config | required_ais: ais}

  @doc "Adds a single AI to the required list."
  @spec put_required_ai(t(), String.t()) :: t()
  def put_required_ai(%__MODULE__{} = config, ai) when is_binary(ai),
    do: %__MODULE__{config | required_ais: [ai | config.required_ais]}

  @doc "Sets (replaces) list of forbidden AIs."
  @spec set_forbidden_ais(t(), list()) :: t()
  def set_forbidden_ais(%__MODULE__{} = config, ais) when is_list(ais),
    do: %__MODULE__{config | forbidden_ais: ais}

  @doc "Adds a single AI to the forbidden list."
  @spec put_forbidden_ai(t(), String.t()) :: t()
  def put_forbidden_ai(%__MODULE__{} = config, ai) when is_binary(ai),
    do: %__MODULE__{config | forbidden_ais: [ai | config.forbidden_ais]}

  @doc "Sets (replaces) map of constraints."
  @spec set_constraints(t(), map()) :: t()
  def set_constraints(%__MODULE__{} = config, constraints) when is_map(constraints),
    do: %__MODULE__{config | constraints: constraints}

  @doc """
  Adds a custom validation constraint for a specific AI.

  ## Examples

      iex> GS1.ValidatorConfig.new()
      ...> |> GS1.ValidatorConfig.put_constraint("01", fn val -> String.length(val) == 14 end)
  """
  @spec put_constraint(t(), String.t(), Constraint.predicate()) :: t()
  def put_constraint(%__MODULE__{} = config, ai, fun) when is_binary(ai) and is_function(fun, 1),
    do: %__MODULE__{config | constraints: Map.put(config.constraints, ai, fun)}
end
