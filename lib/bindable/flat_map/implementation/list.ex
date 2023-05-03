defimpl Bindable.FlatMap, for: List do
  @spec flat_map(list(a), (a -> list(b))) :: list(b) when a: var, b: var
  defdelegate flat_map(as, f), to: Enum
end
