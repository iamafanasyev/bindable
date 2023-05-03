defimpl Bindable.FlatMap, for: Stream do
  @spec flat_map(Enumerable.t(a), (a -> Enumerable.t(b))) :: Enumerable.t(b) when a: var, b: var
  defdelegate flat_map(as, f), to: Stream
end
