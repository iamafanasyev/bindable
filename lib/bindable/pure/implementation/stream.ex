defimpl Bindable.Pure, for: Stream do
  @spec of(Enumerable.t(a), a) :: Enumerable.t(a) when a: var
  def of(_, a), do: %Stream{enum: [a]}
end
