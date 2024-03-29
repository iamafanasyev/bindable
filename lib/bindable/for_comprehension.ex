defmodule Bindable.ForComprehension do
  @moduledoc """
  Elixir for-comprehension that goes beyond the `List`s.

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

        iex> import Bindable.ForComprehension
        ...> bindable for x <- [1, 2], y <- [3, 4], x < 2, do: {x, y}
        [{1, 3}, {1, 4}]

  In this case the guard does not refer to the last generated value,
  so the expression can be refactored to apply the guard *before* the last generator.
  It can dramatically improve performance of the whole expression in general!

        iex> import Bindable.ForComprehension
        ...> bindable for x <- [1, 2], x < 2, y <- [3, 4], do: {x, y}
        [{1, 3}, {1, 4}]

  That is why `flatMap` + `pure` was used for implementation,
  so assigns could be implemented in a most straightforward way,
  while preserving all compiler warnings. Compiler would warn you (about unused variable),
  if you try to apply the guard, which does not refer to the last generated value.
  """

  @doc """
  Elixir for-comprehension that goes beyond the `List`s.

  Elixir does not have variadic functions or macros.
  But Elixir's for-comprehension looks exactly like variadic macro:

        iex> for(x <- [1, 2], y <- [3, 4], do: {x, y})
        [{1, 3}, {1, 4}, {2, 3}, {2, 4}]

  That's because it is actually a `Kernel.SpecialForms.for/1`, treated "specially" by compiler.
  So to emulate variadic nature of for-comprehension (e.g. it can have one or many generators)
  macro application was used (macro applied to `Kernel.SpecialForms.for/1` expression):

        iex> import Bindable.ForComprehension
        ...> bindable for x <- [1, 2], y <- [3, 4], do: {x, y}
        [{1, 3}, {1, 4}, {2, 3}, {2, 4}]

  It also supports `Kernel.SpecialForms.for/1`-like guards and assigns.
  """
  defmacro bindable({:for, _, [{:<-, _, [generated_value_pattern, generator]} | rest_with_yield]}) do
    quote do
      require Bindable.ForComprehension

      Bindable.ForComprehension.do_for(
        [],
        [],
        unquote(generated_value_pattern),
        unquote(generator),
        unquote(rest_with_yield)
      )
    end
  end

  defmacro bindable({:for, _, [{:<-, _, [generated_value_pattern, generator]} | rest]}, do: yield) do
    rest_with_yield =
      rest ++ [[do: yield]]

    quote do
      require Bindable.ForComprehension

      Bindable.ForComprehension.do_for(
        [],
        [],
        unquote(generated_value_pattern),
        unquote(generator),
        unquote(rest_with_yield)
      )
    end
  end

  @doc """
  "Private" macro to implement `for/2`.

  Due to Elixir's macro expand process nature you can't have this `do_for` macro as a "private" one.
  It would require `do_for` import at the call-site, which is impossible for "private"-macro (defined by `defmacrop`).
  """
  defmacro do_for(
             reverse_ordered_assigns,
             reverse_ordered_guards,
             generated_value_pattern,
             generator,
             [[do: yield]]
           ) do
    capture_definitions =
      {:__block__, [],
       reverse_ordered_assigns
       |> Stream.map(fn {x, definition} -> {:=, [], [x, definition]} end)
       |> Enum.reverse()}

    capture_guards =
      reverse_ordered_guards
      |> Stream.map(fn p -> quote do: fn unquote(generated_value_pattern) -> unquote(p) end end)
      |> Enum.reverse()

    quote do
      unquoted_generator = unquote(generator)

      Bindable.FlatMap.flat_map(unquoted_generator, fn generated_value ->
        with unquote(generated_value_pattern) <- generated_value do
          unquote(capture_definitions)

          if Enum.all?(unquote(capture_guards), & &1.(generated_value)) do
            Bindable.Pure.of(unquoted_generator, unquote(yield))
          else
            Bindable.Empty.of(unquoted_generator)
          end
        else
          _generated_value_pattern_mismatch ->
            Bindable.Empty.of(unquoted_generator)
        end
      end)
    end
  end

  defmacro do_for(
             reverse_ordered_assigns,
             reverse_ordered_guards,
             generated_value_pattern,
             generator,
             [{:<-, _, [next_generated_value_pattern, next_generator]} | rest_with_yield]
           ) do
    capture_definitions =
      {:__block__, [],
       reverse_ordered_assigns
       |> Stream.map(fn {x, definition} -> {:=, [], [x, definition]} end)
       |> Enum.reverse()}

    capture_guards =
      reverse_ordered_guards
      |> Stream.map(fn p -> quote do: fn unquote(generated_value_pattern) -> unquote(p) end end)
      |> Enum.reverse()

    quote do
      require Bindable.ForComprehension

      unquoted_generator = unquote(generator)

      Bindable.FlatMap.flat_map(unquoted_generator, fn generated_value ->
        with unquote(generated_value_pattern) <- generated_value do
          unquote(capture_definitions)

          if Enum.all?(unquote(capture_guards), & &1.(generated_value)) do
            Bindable.ForComprehension.do_for(
              [],
              [],
              unquote(next_generated_value_pattern),
              unquote(next_generator),
              unquote(rest_with_yield)
            )
          else
            Bindable.Empty.of(unquoted_generator)
          end
        else
          _generated_value_pattern_mismatch ->
            Bindable.Empty.of(unquoted_generator)
        end
      end)
    end
  end

  defmacro do_for(
             reverse_ordered_assigns,
             reverse_ordered_guards,
             generated_value_pattern,
             generator,
             [{:=, _, [b, definition]} | rest_with_yield]
           ) do
    extended_reverse_ordered_assigns =
      [{b, definition} | reverse_ordered_assigns]

    quote do
      require Bindable.ForComprehension

      Bindable.ForComprehension.do_for(
        unquote(extended_reverse_ordered_assigns),
        unquote(reverse_ordered_guards),
        unquote(generated_value_pattern),
        unquote(generator),
        unquote(rest_with_yield)
      )
    end
  end

  defmacro do_for(
             reverse_ordered_assigns,
             reverse_ordered_guards,
             generated_value_pattern,
             generator,
             [guard | rest_with_yield]
           ) do
    extended_reverse_ordered_guards =
      [guard | reverse_ordered_guards]

    quote do
      unquoted_generator = unquote(generator)

      Bindable.Empty.impl_for!(unquoted_generator)

      require Bindable.ForComprehension

      Bindable.ForComprehension.do_for(
        unquote(reverse_ordered_assigns),
        unquote(extended_reverse_ordered_guards),
        unquote(generated_value_pattern),
        unquoted_generator,
        unquote(rest_with_yield)
      )
    end
  end
end
