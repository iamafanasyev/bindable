defimpl Bindable.FlatMap, for: Bindable.Maybe do
  @spec flat_map(Bindable.Maybe.t(a), (a -> Bindable.Maybe.t(b))) :: Bindable.Maybe.t(b)
        when a: var, b: var
  def flat_map(%Bindable.Maybe{value: %Bindable.Maybe.Nothing{}} = nothing, _f), do: nothing

  def flat_map(%Bindable.Maybe{value: %Bindable.Maybe.Just{value: a}}, f) do
    f.(a)
  end
end
