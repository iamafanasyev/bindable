defimpl Bindable.Pure, for: List do
  @spec of(list(a), a) :: list(a) when a: var
  def of(_, a), do: [a]
end
