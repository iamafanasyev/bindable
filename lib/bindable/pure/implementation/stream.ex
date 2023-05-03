defimpl Bindable.Pure, for: Stream do
  @spec of(Enumerable.t(a), a) :: Enumerable.t(a) when a: var
  def of(_, a), do: [a] |> Stream.cycle() |> Stream.take(1)
end
