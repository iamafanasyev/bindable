defprotocol Bindable.Empty do
  @moduledoc """
  "Type class" to represent a failed or empty computation.

  Informally, it defines "filtering" semantics for your type.
  By implementing it you enable guards inside for-comprehension for your type.

  Inspired by `Alternative`'s `empty`.
  """

  @typep m(_a) :: any()

  @doc """
  Provides a default or fallback value in cases where a computation fails or has no result.

  Returns an "empty"-value of the type provided by `example`.
  """
  @spec of(example :: m(a)) :: empty_value :: m(a) when a: var
  def of(ma)
end
