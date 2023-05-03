defprotocol Bindable.Pure do
  @moduledoc """
  "Type class" to create a computation that has no effect other than to produce a value.

  Required to enable for-comprehension for your type.

  Inspired by `Applicative`'s `pure`.
  """

  @typep m(_a) :: any()

  @doc """
  Create a computation that has no effect other than to produce a value.

  Returns a "pure"-value of the type provided by `example`.
  """
  @spec of(example :: m(a), a) :: pure_value :: m(a) when a: var
  def of(ma, a)
end
