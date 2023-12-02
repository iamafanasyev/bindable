defmodule Bindable do
  @moduledoc """
  Elixir for-comprehension that goes beyond the `List`s.

        iex> import Bindable.ForComprehension
        ...> import Bindable.Maybe
        ...>
        ...> bindable for x <- just(1),
        ...>              y <- just(2),
        ...>              x + y > 4,
        ...>              z <- just(3),
        ...>          do: x + y + z
        nothing()

  For-comprehension is a common syntax construct in functional programming languages,
  that allows you to express complex operations on collections and monadic contexts in a concise and expressive way.
  More formally, it is a way to construct monadic value by describing it as a sequence of effectful computations.
  To do so, it provides following constructs to combine such computations into new monadic value:
   * Generator (commonly known as iterator for lists): extracts value from the monadic context.
   * Guard (or filter): filters generated values based on a predicate (see `Bindable.Empty`).
   * Assign: aliases any expression inside current scope.
   * Yield: defines resulting value to return inside the monadic context.

  Here comes an example of them:

        iex> import Bindable.ForComprehension
        ...>
        ...> xs = [[10, 20], [30]]
        ...> bindable for x <- xs,       # generator
        ...>              length(x) > 1, # guard
        ...>              y <- x,        # next generator
        ...>              z = y + 1,     # assign
        ...>              y + z > 21,    # another guard
        ...>          do: {y, z}         # yield
        [{20, 21}]

  Elixir's kernel provides for-comprehension ***only*** for lists.
  It works with any `Enumerable`, however it always (eagerly) yields `List`
  (so you can't *describe* `Stream` using `Kernel.SpecialForms.for/1`).
  `Bindable` already comes with for-comprehension batteries for:
   * `List`
   * `Bindable.Maybe`
   * `Stream`

  So you can lazily create new stream out of provided ones:

        iex> import Bindable.ForComprehension
        ...>
        ...> lazy_xs = Stream.take(1..5, 2)
        ...> lazy_ys = Stream.take(5..9, 2)
        ...> lazy_xys = bindable for x <- lazy_xs,
        ...>                         y <- lazy_ys,
        ...>                     do: {x, y}
        ...>
        ...> {is_list(lazy_xys), Enum.to_list(lazy_xys)}
        {false, [{1, 5}, {1, 6}, {2, 5}, {2, 6}]}

  ***The main goal*** of the library is to provide for-comprehension beyond lists with *the least* amount of overhead.
  So it doesn't aim to provide a principled way to define type classes (required by for-context),
  e.g. it doesn't provide any sensible way to enforce type class properties on implementations.
  To stick with "the least amount of overhead" paradigm type classes implemented atop of Elixir protocols.

  "Minimal complete definition" for you data type to be compliant with for-comprehension includes:
   * `Bindable.FlatMap` implementation to chain sequential generators;
   * `Bindable.Pure` implementation to yield resulting value (design decision, see `Bindable.ForComprehension`).

  If you want to use guards/filters inside for-comprehension with your data type,
  you should also provide an implementation for `Bindable.Empty`, so it is optional,
  e.g. when your data type does not provide any meaningful semantics for empty/filtered value effect.
  """
end
