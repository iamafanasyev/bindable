defimpl Bindable.Empty, for: Bindable.Maybe do
  @spec of(Bindable.Maybe.t(any())) :: Bindable.Maybe.nothing()
  def of(_), do: Bindable.Maybe.nothing()
end
