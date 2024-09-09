---
title: You Don't need Ecto.Multi
slug: you_dont_need_ecto_multi
is_draft: false
reading_time_minutes:
published_at: 2024-09-09 12:05:11Z
tags:
  - elixir
  - ecto
---

Last week, I attended [ElixirConf US 2024](https://elixirconf.com/2024) and watched a talk by [Miki Rezentes](https://twitter.com/mikirez) titled "Using Ecto.Multis, Oban and Transaction Callbacks to Isolate Concepts".

The talk was great, but one thing it reminded me of was that [Ecto.Multi](https://hexdocs.pm/ecto/Ecto.Multi.html) exists.

`Ecto.Multi` is something I've been meaning to write about for awhile now, and I think now is as good a time as any!

## Preamble

I've honestly never written a single `Ecto.Multi`, and honestly at first glance, I'm not sure I ever will.

I think `Ecto.Multi` is a tool without much of a use case, and whilst comparing what it does to `function coloring` might be a bit of a stretch, I think at least in some way it's a good analogy.

> Note: If I wasn't clear: I'm not saying it _is_ function coloring. Semantically speaking, that isn't the case.
>
> The use of `Ecto.Multi` does force your surrounding code to be written in a multi-aware way, however, and its use can be contagious.
>
> Function coloring is a term used to describe how certain languages have two distinct ways to write functions: synchronous and asynchronous.
>
> In these sorts of languages, you can't call asynchronous functions from within synchronous functions without marking the calling function as asynchronous as well.
>
> This leads to a situation where you have to mark all of your functions as asynchronous, even if they don't do anything asynchronously, just because they call an asynchronous function.
>
> This is a problem because it couples the _way_ a function is run with its implementation, which is a bad thing.
>
> See [this blog post](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/) for a more in-depth explanation.

## Ecto.Multi

With that out the way, let's talk about `Ecto.Multi`.

[Ecto](https://hexdocs.pm/ecto/Ecto.html) is a database wrapper for Elixir that provides a lot of nice features for working with databases.

One such feature is the ability to work with database transactions.

A transaction is a way to group a series of database operations together such that they all succeed or fail together. Nothing is committed to the database until the transaction is complete.

Ecto provides two ways to work with transactions:

1. `Ecto.Repo.transaction/1` which is a function.
2. `Ecto.Multi` which is a data structure.

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

This builds up a data structure representing each step of a given transaction. Each step can do database operations and their results are stored under the provided key (the 2nd argument).

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
    |> Ecto.Multi.insert(:user, &do_create_user(&1, &1, attrs))
    |> Ecto.Multi.insert(:profile, Profile.changeset(%Profile{}, %{user_id: :user.id}))
    |> Ecto.Multi.run(:send_welcome_email, &send_welcome_email_multi/2)
    |> Repo.transaction()
  end

  defp do_create_user(multi, _repo, attrs) do
    user = User.changeset(%User{}, attrs)
    Ecto.Multi.insert(multi, :user, user)
  end

  defp send_welcome_email_multi(_repo, %{user: user}) do
    Emails.send_welcome_email(user)
  end
end
```

Note that already we're starting to have to write functions such as `do_create_user/3` and `send_welcome_email_multi/2` that are tightly coupled to the APIs `Ecto.Multi` expects.

Now what happens if we introduce `Admin` as a type of account?

```elixir
defmodule MyApp.Accounts do
  def create_user(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, &do_create_user(&1, &1, attrs))
    |> Ecto.Multi.insert(:profile, Profile.changeset(%Profile{}, %{user_id: :user.id}))
    |> Ecto.Multi.run(:send_welcome_email, &send_welcome_email_multi/2)
    |> Repo.transaction()
  end

  def create_admin(attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:admin, &do_create_admin(&1, &1, attrs))
    |> Ecto.Multi.insert(:profile, Profile.changeset(%Profile{}, %{user_id: :admin.id}))
    |> Ecto.Multi.run(:send_welcome_email, &send_welcome_email_multi/2)
    |> Repo.transaction()
  end

  defp do_create_admin(multi, _repo, attrs) do
    admin = Admin.changeset(%Admin{}, attrs)
    Ecto.Multi.insert(multi, :admin, admin)
  end

  defp do_create_user(multi, _repo, attrs) do
    user = User.changeset(%User{}, attrs)
    Ecto.Multi.insert(multi, :user, user)
  end

  defp send_welcome_email_multi(_repo, multi_params) do
    Emails.send_welcome_email(multi_params.user || multi_params.admin)
  end
end
```

Now we have to duplicate the `send_welcome_email_multi/2` function to handle both `User` and `Admin` types. This is a fixable problem, but we're literally having to wrap another function just to handle the different types.

What about if like the `Profile.changeset/3` call, we need to reach out to another module? This is fine in the case of `Profile` assuming that its a sub-context of the `MyApp.Accounts` context, but it could equally well be anything.

The point is that `Ecto.Multi` forces you to write your code in a certain way, and it prevents you from leveraging stupid, simply function composition.

## Functional Composition vs Data Composition

The problem with `Ecto.Multi` is that it forces you to compose your functions using data, rather than functions.

The above example could be written like this:

```elixir
defmodule MyApp.Accounts do
  def create_user(attrs) do
    Repo.transaction(fn ->
      %User{} = Repo.insert!(User.changeset(%User{}, attrs))
      %Profile{} = Repo.insert!(Profile.changeset(%Profile{}, %{user_id: user.id}))
      :ok = send_welcome_email(user)

      %User{user | profile: profile}
    end)
  end

  def create_admin(attrs) do
    Repo.transaction(fn ->
      %Admin{} = Repo.insert!(Admin.changeset(%Admin{}, attrs))
      %Profile{} = Repo.insert!(Profile.changeset(%Profile{}, %{user_id: admin.id}))
      :ok = Emails.send_welcome_email(admin)

      %Admin{admin | profile: profile}
    end)
  end
end
```

This example just works as expected. It might just be because I'm used to the syntax, but I find this much easier to read and understand. We're literally just calling functions per normal.

> Aside: another win is that if you're writing code sans transactions, and you decide you need to wrap some operations within a transaction, you can just wrap the existing code in a transaction block.
>
> With `Ecto.Multi`, you'd have to rewrite the entire function and any other functions called within it to be "multi-aware".

When trying to research the benefits of `Ecto.Multi`, I found a lot of people saying arguing for the following things. Let's take a closer look!

### Error Handling

I think this probably deserves a blog post of its own, but I think the argument that `Ecto.Multi` is good for error handling is a bit of a red herring.

While `Ecto.Multi` does return you errors when a step fails, so does `Repo.transaction/1`. The only difference is that with `Ecto.Multi`, you're given a syntax to "name" your steps.

This is a good thing, but I'd argue that it's not worth the trade-off of having to write your code in a certain way.

If we accept needing to write code in certain ways, you can always write your standard `Ecto.Repo.transaction/2` callbacks thusly:

```elixir
def create_user(attrs) do
  Repo.transaction(fn ->
    with {:ok, user} <- create_user!(attrs),
         {:ok, profile} <- create_profile!(user)
         :ok <- send_welcome_email(user) do
      %User{user | profile: profile}
    else
      {:error, reason} -> Repo.rollback(reason)
    end
  end)
end
```

I'd argue this is not surprising in the slightest.

> Note: At Vetspire, we even prefer to call the exception-throwing variants of functions so that code doesn't need to be wrapped in any kind of control flow.

This is common enough of a thing that you can implement your own `with` macro that does this for you.

In fact, [Sasa Juric](https://twitter.com/sasajuric) has a good open source implementation you can use [here](https://github.com/sasa1977/mix_phx_alt/blob/develop/lib/core/repo.ex).

### Dynamic Transaction Steps

One oft-cited advantage of `Ecto.Multi` is that you can dynamically build up the steps of a transaction.

This is true, as you can reduce over some list of states/input data and incrementally build up the transaction steps to run at the end.

While this is certainly a valid use case, I'd argue that it's not a common one: I can't think of many cases where I'd prefer to do that rather than writing steps out explicitly...

That isn't to say its without its merits. If you try to write your own generic implementation of such a thing, you'd end up re-implementing your own version of `Ecto.Multi` anyway.

If your workflow requires this sort of dynamic transaction building, then `Ecto.Multi` is probably the right tool for the job.

### Enforcing Constraints

One possible benefit of `Ecto.Multi` is the ability to enforce constraints on the order of operations prior to execution.

At Vetspire, we have a `Billing` context that handles all of our billing logic: handling the creation of orders, line items, payment, etc.

In this context, it could be helpful that any mutation that is financially material needs to ensure it has a lock on all the necessary resources before proceeding.

We do this manually at the moment by ensuring that all of our business logic functions operate in transactions, and begin their transactions by acquiring locks on the necessary resources.

However, it would be possible to write a higher-order function that can reflect on a multi to automatically acquire these locks.

Again, a valid use case, but not one that I think is common enough to warrant the use of `Ecto.Multi` in general.

## Conclusion

I think `Ecto.Multi` is a tool that is overused in the Elixir community.

Its use isn't bad per se, but I think it can be difficult to find a definitive reason to use it over `Ecto.Repo.transaction/1`.

If you want more streamlined error handling, I'd suggest reaching for a `with` macro that can handle exceptions for you such as `Repo.transact/2` before opting for `Ecto.Multi`.

I'd love to hear your thoughts and opinions on this though!

Happy Hacking!!
