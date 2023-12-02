# Bindable

[![Elixir CI](https://github.com/iamafanasyev/bindable/actions/workflows/elixir.yml/badge.svg)](https://github.com/iamafanasyev/bindable/actions/workflows/elixir.yml)

For-comprehension at your service.

```elixir
alias Bindable.Maybe
require Bindable.ForComprehension

Bindable.ForComprehension.for {
  x <- Maybe.just(1),
  y <- Maybe.just(2),
  if(x + y > 4),
  z <- Maybe.just(3)
} do
  x + y + z
end === Maybe.nothing()
```

## For-comprehension

For-comprehension is a common syntax construct in functional programming languages,
that allows you to express complex operations on collections and monadic contexts in a concise and expressive way.
More formally, it is a way to construct monadic value by describing it as a sequence of effectful computations.
To do so, it provides following constructs to combine such computations into new monadic value:
 * Generator (commonly known as iterator for lists): extracts value from the monadic context.
 * Guard (or filter): filters generated values based on a predicate (see `Bindable.Empty`).
 * Assign: aliases any expression inside current scope.
 * Yield: defines resulting value to return inside the monadic context.

```elixir
require Bindable.ForComprehension

xs = [[10, 20], [30]]
Bindable.ForComprehension.for {
  x <- xs,           # generator
  if(length(x) > 1), # guard
  y <- x,            # next generator
  z = y + 1,         # assign
  if(y + z > 21)     # another guard
} do
  {y, z}             # yield
end === [{20, 21}]
```

## Usage

Elixir's kernel provides for-comprehension ***only*** for lists.
It works with any `Enumerable`, however it always (eagerly) yields `List`
(so you can't *describe* `Stream` using `Kernel.SpecialForms.for/1`).
`Bindable` already comes with for-comprehension batteries for:
 * `List`,
 * `Maybe`,
 * `Stream`.

"Minimal complete definition" for you data type to be compliant with for-comprehension includes:
 * `Bindable.FlatMap` implementation to chain sequential generators;
 * `Bindable.Pure` implementation to yield resulting value (design decision, see `Bindable.ForComprehension`).

If you want to use guards/filters inside for-comprehension with your data type,
you should also provide an implementation for `Bindable.Empty`, so it is optional,
e.g. when your data type does not provide any meaningful semantics for empty/filtered value effect.

***The main goal*** of the library is to provide for-comprehension beyond lists with *the least* amount of overhead.
So it doesn't aim to provide a principled way to define type classes (required by for-context),
e.g. it doesn't provide any sensible way to enforce type class properties on implementations.
To stick with "the least amount of overhead" paradigm type classes implemented atop of Elixir protocols.

## Installation

The package can be installed by adding `bindable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bindable, "~> 1.0.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/bindable>.

