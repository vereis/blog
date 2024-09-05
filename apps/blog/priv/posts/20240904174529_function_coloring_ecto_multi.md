---
title: Function Coloring
slug: function_coloring_ecto_multi
is_draft: true
reading_time_minutes:
published_at: 2024-09-10 12:05:11Z
tags:
  - elixir
  - languages
---

I've been meaning to write about this for a while now.

Last week, I attended [ElixirConf US 2024](https://elixirconf.com/2024) and watched a talk by [Miki Rezentes](https://twitter.com/mikirez) titled "Using Ecto.Multis, Oban and Transaction Callbacks to Isolate Concepts".

The talk was great, but one thing it reminded me of was that [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html) exists.

I've honestly never written a single `Ecto.Multi`, and honestly at first glance, I'm not sure I ever will.

tl;dr -- code that uses `Ecto.Multi` infects adjacent code much like function coloring in other languages, and that's a bad thing.

> Note: I'm not saying it _is_ function coloring. Semantically speaking, that isn't the case.
>
> The use of `Ecto.Multi` does force your surrounding code to be written in a multi-aware way, however, and its use can be contagious.

## ELI5: Function Coloring

Function coloring is a relatively newfangled term that I believe originates from [Bob Nystrom](https://twitter.com/munificentbob).

For a full explanation, I recommend reading [this blog post](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/). I think this is probably one of the clearest explanations of the concept.

There's also a good YouTube video by [ThePrimeagen](https://www.youtube.com/watch?v=MoKe4zvtNzA) that goes over it some.

But in short, function coloring is a term used to describe how in certain programming languages such as `JavaScript`, there are actually two distinct ways to write functions:

1. Functions defined with the `function` keyword or via an anonymous function expression.
2. Asynchronous functions defined with the `async` keyword.

The problem arises when you mix these two types of functions in the same codebase.

In order to call an asynchronous function from within a synchronous function, you must use the `await` keyword. But doing so means that the calling function must also be marked as `async`.

This `async` keyword then infects all of the functions that call it, and so on and so forth.

Again, I recommend reading the blog post or watching the video for a more in-depth explanation, but that's the five second gist of it.

## Function Coloring in Elixir

Elixir does not suffer from function coloring in the same way that `JavaScript` does.

There is no concept of synchronous or asynchronous functions in Elixir. All functions are synchronous -- every single function that executes on a given instance of the BEAM lives in a process.

Those processes run concurrently, but the functions themselves, the literal code they run, are synchronous from the point of view of the process executing them.

Instead of having special syntax at the language level to denote async functions, and to fetch their results, everything in Elixir is just message passing.

When you want to call an async function and immediately await its results, you can simply tell the running process to block until it receives a message back, and then it either times out or continues.

```elixir
iex> spawn(fn ->
...>   result = Enum.map(1..100, & &1 * 2)
...>   send(self(), {:result, result})
...> end)
<0.123.0>
iex> receive do
...>   {:result, result} -> result
...> end
[2, 4, 6, 8, 10, ...]
```

This is a contrived example, but it demonstrates how you can achieve the same effect as `await` in `JavaScript` without needing special syntax.

Note that doing this means you can't tell, as the caller of a function, whether or not that function does anything concurrently in its implementation.

This is a good thing, since you're not coupling the _way_ a function is run with its implementation.

## Ecto.Multi

However! `Ecto.Multi` is a different thing entirely.

[Ecto](https://hexdocs.pm/ecto/Ecto.html) is a database wrapper for Elixir that provides a lot of nice features for working with databases.

One such feature is the ability to work with database transactions.

A transaction is a way to group a series of database operations together such that they all succeed or fail together. Nothing is committed to the database until the transaction is complete.

Ecto provides two ways to work with transactions:

1. `Ecto.Repo.transaction/1`
2. `Ecto.Multi`

`Ecto.Repo.transaction/1` is a function that takes a function as an argument. The contents of that function are executed within a transaction, like so:

```elixir
iex> Repo.transaction(fn ->
...>   alice = Repo.insert!(%User{name: "Alice"})
...>   bob = Repo.insert!(%User{name: "Bob"})
...>
...>   {alice, bob}
...> end)
{:ok, {%User{...}, %User{...}}}
```

This same code could be written using `Ecto.Multi` like so:

```elixir
iex> alias Ecto.Multi
iex> Ecto.Multi.new()
...> |> Ecto.Multi.insert(:alice, User.changeset(%User{}, %{name: "Alice"}
...> |> Ecto.Multi.insert(:bob, User.changeset(%User{}, %{name: "Bob"}))
...> |> Repo.transaction()
{:ok, %{alice: %User{...}, bob: %User{...}}}
```

This builds up a datastructure representing each step of a given transaction. Each step can do database operations and their results are stored under the provided key (the 2nd argument).

The transaction is then executed when `Repo.transaction/1` is called. If any steps fail, the transaction is rolled back and an error is returned.

The `Ecto.Multi` version might read better with this simple example, but honestly I'd argue it really doesn't.

I talk about this issue in my post [The Case against Pipes](/case_against_pipes), but the problem here is that the Elixir community has a tendency to overuse the pipe operator.

The pipe operator is great for chaining functions together, but it's not always the best choice. Especially when you need to introduce things such as error handling or branching logic.

`Ecto.Multi`, in my humble opinion, is a prime example of this.

## The Problem

For any non-contrived example, your code using `Ecto.Multi` might end up looking like this:

```elixir
defmodule MyApp.Accounts do
  def create_user(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.changeset(%User{}, attrs))
    |> Ecto.Multi.insert(:profile, Profile.changeset(%Profile{}, %{user_id: :user.id}))
    |> Ecto.Multi.run(:send_welcome_email, fn %{user: user} ->
      send_welcome_email(user)
    end)
    |> Repo.transaction()
  end
end
```

## Functional Composition vs Data Composition

## Transactions
