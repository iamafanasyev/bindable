defimpl Bindable.Pure, for: Bindable.Maybe do
  @spec of(Bindable.Maybe.t(a), a) :: Bindable.Maybe.t(a) when a: var
  def of(_, a), do: Bindable.Maybe.just(a)
end
