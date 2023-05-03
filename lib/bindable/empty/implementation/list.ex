defimpl Bindable.Empty, for: List do
  @spec of(list(any())) :: []
  def of(_), do: []
end
