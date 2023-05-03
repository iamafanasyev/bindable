defprotocol Bindable.FlatMap do
  @moduledoc """
  "Type class" to chain together computations that have a context or effect.

  Required to enable for-comprehension for your type.

  Inspired by `Monad`'s `bind` (also known as `flatMap` or `>>=`).
  """

  @typep m(_a) :: any()

  @doc """
  Takes a computation that produces a value of type `a` and a function,
  that takes that value and produces a new computation, that produces a value of type `b`.
  The key feature is that it allows the function to access the value produced by the first computation
  and use it to construct the second computation (in contrast with `Applicative`'s `<|>`).
  """
  @spec flat_map(m(a), (a -> m(b))) :: m(b) when a: var, b: var
  def flat_map(ma, f)
end
