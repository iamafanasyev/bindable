defmodule Bindable.Maybe do
  @moduledoc """
  Yet another `Maybe` implementation.

  `Maybe` is a data type that is used to represent optional values that may or may not be present.
  It is typically used as a safer alternative to using null or undefined values.
  """

  defmodule Just do
    @moduledoc false

    @keys [:value]
    @enforce_keys @keys
    defstruct @keys
  end

  defmodule Nothing do
    @moduledoc false

    defstruct []
  end

  @keys [:value]
  @enforce_keys @keys
  defstruct [:value]

  @type just(a) :: %__MODULE__{value: %Just{value: a}}
  @type nothing() :: %__MODULE__{value: %Nothing{}}

  @type t(a) :: nothing() | just(a)

  @spec just(a) :: just(a) when a: var
  def just(a) do
    %__MODULE__{value: %Just{value: a}}
  end

  @spec nothing() :: nothing()
  def nothing() do
    %__MODULE__{value: %Nothing{}}
  end

  @spec of_nullable(nil | a) :: t(a) when a: var
  def of_nullable(nil), do: nothing()

  def of_nullable(a), do: just(a)
end
