defimpl Bindable.Empty, for: Stream do
  @spec of(Enumerable.t(any())) :: Enumerable.t(any())
  def of(_), do: %Stream{enum: []}
end
