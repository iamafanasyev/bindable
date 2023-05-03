defmodule Bindable.ForComprehension do
  @moduledoc """
  Exposes Scala-like for-comprehension as an Elixir macro.

  For-comprehension (its operations) could be implemented in several ways.
  For example, you can desugar it into chain of `flatMap` + `map` invocation:

        iex> xs = [1, 2]
        ...> ys = [3, 4]
        ...> for(x <- xs, y <- ys, do: {x, y}) === Enum.flat_map(xs, fn x -> Enum.map(ys, fn y -> {x, y} end) end)
        true

  But if you try to implement assigns using `flatMap` + `map`,
  you will end up with doing something like `map(ma, &{&1, assign})`,
  and then each guard, that doesn't utilize every variable of such tuple,
  would raise an unused variable compiler warning (`filter(ma, fn {a, b} -> a > 42 end)`).
  However, suppressing *all* these warning would be a bad idea.
  They are useful to detect several kinds of flaws, while working with for-comprehension.
  For example inefficient guards:

        iex> require Bindable.ForComprehension
        ...> Bindable.ForComprehension.for {x <- [1, 2], y <- [3, 4], if x < 2}, do: {x, y}
        [{1, 3}, {1, 4}]

  In this case the guard does not refer to the last generated value,
  so the expression can be refactored to apply the guard *before* the last generator.
  It can dramatically improve performance of the whole expression in general!

        iex> require Bindable.ForComprehension
        ...> Bindable.ForComprehension.for {x <- [1, 2], if(x < 2), y <- [3, 4]}, do: {x, y}
        [{1, 3}, {1, 4}]

  That is why `flatMap` + `pure` was used for implementation,
  so assigns could be implemented in a most straightforward way,
  while preserving all compiler warnings. Compiler would warn you (about unused variable),
  if you try to apply the guard, which does not refer to the last generated value.
  """

  @doc """
  Scala-like for-comprehension as an Elixir macro.

  Elixir does not have variadic functions or macros.
  But Elixir's for-comprehension looks exactly like variadic macro:

        iex> for(x <- [1, 2], y <- [3, 4], do: {x, y})
        [{1, 3}, {1, 4}, {2, 3}, {2, 4}]

  That's because it is actually a `Kernel.SpecialForms.for/1`, treated "specially" by compiler.
  So to emulate variadic nature of for-comprehension (e.g. it can have one or many generators),
  you have to pass an argument of "variadic nature" (e.g. `List` or `Tuple`).
  `Tuple` was selected to conform with already commonly known Scala for-syntax:

        iex> require Bindable.ForComprehension
        ...> Bindable.ForComprehension.for {x <- [1, 2], y <- [3, 4]}, do: {x, y}
        [{1, 3}, {1, 4}, {2, 3}, {2, 4}]

  It also supports "guards" (i.e. `if x < 42`),
  but Elixir's macro expansion imposes one tricky restriction on the syntax:
  you have to wrap if-expression (predicate) in a brackets,
  so Elixir can distinguish tuple elements from function application (`{..., if(x < 42), y = x + 1, ...}`).
  That is why brackets may be omitted for "trailing"-if (`{..., if x < 42}`).
  """
  defmacro for(_computations = {:{}, _, [{:<-, _, [a, ma]} | rest]}, _yield = [do: yield]) do
    quote do
      import Bindable.ForComprehension, only: [do_for: 6]

      do_for([], [], unquote(a), unquote(ma), unquote(rest), unquote(yield))
    end
  end

  defmacro for({{:<-, _, [a, ma]}, e}, do: yield) do
    quote do
      import Bindable.ForComprehension, only: [do_for: 6]

      do_for([], [], unquote(a), unquote(ma), [unquote(e)], unquote(yield))
    end
  end

  @doc """
  "Private" macro to implement `for/2`.

  Due to Elixir's macro expand process nature you can't have this `do_for` macro as a "private" one.
  It would require `do_for` import at the call-site, which is impossible for "private"-macro (defined by `defmacrop`).
  """
  defmacro do_for(
             reverse_ordered_definitions,
             reverse_ordered_guards,
             a,
             ma,
             _rest_computations = [],
             yield
           ) do
    capture_definitions =
      {:__block__, [],
       reverse_ordered_definitions
       |> Stream.map(fn {x, definition} -> {:=, [], [x, definition]} end)
       |> Enum.reverse()}

    capture_guards =
      reverse_ordered_guards
      |> Stream.map(fn p -> quote do: fn unquote(a) -> unquote(p) end end)
      |> Enum.reverse()

    quote do
      unquoted_ma = unquote(ma)

      Bindable.FlatMap.flat_map(unquoted_ma, fn unquote(a) ->
        unquote(capture_definitions)

        if Enum.all?(unquote(capture_guards), & &1.(unquote(a))) do
          Bindable.Pure.of(unquoted_ma, unquote(yield))
        else
          Bindable.Empty.of(unquoted_ma)
        end
      end)
    end
  end

  defmacro do_for(
             reverse_ordered_definitions,
             reverse_ordered_guards,
             a,
             ma,
             [{:<-, _, [b, mb]} | rest],
             yield
           ) do
    capture_definitions =
      {:__block__, [],
       reverse_ordered_definitions
       |> Stream.map(fn {x, definition} -> {:=, [], [x, definition]} end)
       |> Enum.reverse()}

    capture_guards =
      reverse_ordered_guards
      |> Stream.map(fn p -> quote do: fn unquote(a) -> unquote(p) end end)
      |> Enum.reverse()

    quote do
      import Bindable.ForComprehension, only: [do_for: 6]

      unquoted_ma = unquote(ma)

      Bindable.FlatMap.flat_map(unquoted_ma, fn unquote(a) ->
        unquote(capture_definitions)

        if Enum.all?(unquote(capture_guards), & &1.(unquote(a))) do
          do_for([], [], unquote(b), unquote(mb), unquote(rest), unquote(yield))
        else
          Bindable.Empty.of(unquoted_ma)
        end
      end)
    end
  end

  defmacro do_for(
             reverse_ordered_definitions,
             reverse_ordered_guards,
             a,
             ma,
             [{:if, _, [p]} | rest],
             yield
           ) do
    extended_reverse_ordered_guards = [p | reverse_ordered_guards]

    quote do
      unquoted_ma = unquote(ma)

      Bindable.Empty.impl_for!(unquoted_ma)

      import Bindable.ForComprehension, only: [do_for: 6]

      do_for(
        unquote(reverse_ordered_definitions),
        unquote(extended_reverse_ordered_guards),
        unquote(a),
        unquoted_ma,
        unquote(rest),
        unquote(yield)
      )
    end
  end

  defmacro do_for(
             reverse_ordered_definitions,
             reverse_ordered_guards,
             a,
             ma,
             [{:=, _, [b, definition]} | rest],
             yield
           ) do
    extended_reverse_ordered_definitions = [{b, definition} | reverse_ordered_definitions]

    quote do
      import Bindable.ForComprehension, only: [do_for: 6]

      do_for(
        unquote(extended_reverse_ordered_definitions),
        unquote(reverse_ordered_guards),
        unquote(a),
        unquote(ma),
        unquote(rest),
        unquote(yield)
      )
    end
  end
end
