---
title: Ecto Queryable Pattern
slug: ecto-queries-are-data
is_draft: false
reading_time_minutes:
published_at: 2024-09-03 10:03:31Z
description: |
  Ecto queries are just data! This post goes over how we can abuse that fact to build ergonomic, composable query patterns.

  Using behaviors, callbacks, and metaprogramming, we can create a single source of truth for query logic that works everywhere.
tags:
  - elixir
  - ecto
---

In Elixir, [Ecto](https://hexdocs.pm/ecto/Ecto.html) is a fantastic library for doing all sorts of database operations in Elixir and is definitely a superpower of the language and ecosystem.

Now, `ecto` isn't just your run-of-the-mill ORM; instead, `ecto` gives you three main things:

1. A way to define schemas which (optionally) map to your database tables.
2. A way to define changesets which validate and cast data to your schemas.
3. A way to build queries which can be composed and executed against your database.

This post is going to focus on the third point; building queries. Unlike traditional ORMs, `ecto` doesn't _control_ your database queries and the like. Instead, `ecto` gives you a way to build queries as data structures which can be composed and manipulated in a functional way.

These queries are then passed to your database adapter (usually `Postgrex` or `Mariaex`) which then translates the query into SQL and sends it off to your database.

At face value, it looks and feels pretty similar, but the key difference is that you're not writing SQL strings; you're building queries as data structures.

## ELI5: Ecto Queries

If you're not familiar with Ecto Queries, here's a quick rundown...

You can build queries via the `Ecto.Query` module which provides a bunch of functions for building queries.

The most common way to build queries is to use the `from` macro which lets you define a query like so:

```elixir
from u in User,
  where: u.age > 18,
  select: u.name
```

Which would generate the following SQL (if passed into a standard SQL adapter):

```sql
SELECT u.name FROM users AS u WHERE u.age > 18
```

Alternatively, because Elixir loves its pipes, you can build queries using the `Ecto.Query` module like so:

```elixir
User
|> where([u], u.age > 18)
|> select([u], u.name)
```

Which generates the same query.

You can pass this query to your database adapter to execute it and get the results back. I'm going to assume you've followed the [Ecto Docs](https://hexdocs.pm/ecto/Ecto.html) and you've got a `MyApp.Repo` module which you can pass queries to.

To run your queries, you can use them like so:

```elixir
iex> MyApp.Repo.all(query)
[%User{}, %User{}, ...]

iex> MyApp.Repo.one(from x in query, limit: 1)
%User{}

iex> MyApp.Repo.aggregate(query, :count)
42
```

However, something that might be surprising, is that your queries are _just data._ You can inspect them, poke them, prod them, and mutate them as you see fit. Check this out:

```elixir
iex> IO.inspect(query, structs: false) # Don't pretty print structs so we get the raw data shown
%{
  __struct__: Ecto.Query,
  from: %{ line: 2, file: "iex", source: {"users", User}, __struct__: Ecto.Query.FromExpr, },
  wheres: [
    %{
      line: 2,
      file: "iex",
      expr: {:>, [], [{{:., [], [{:&, [], [0]}, :age]}, [], []}, {:^, [], [0]}]},
      op: :and,
      params: [...],
      __struct__: Ecto.Query.BooleanExpr,
      ...
    }
  ],
  order_bys: [],
  updates: [],
  assocs: [],
  joins: [],
  group_bys: [],
  havings: [],
  ...
}
```

Now, the complexity of the `Ecto.Query.t()` struct is pretty complex, hence the useful functions and macros provided which operate on them. However, the key takeaway is that you can build, inspect, and manipulate queries as data structures.

This is a pretty powerful concept, and it's something that we can leverage to build some pretty cool abstractions and patterns -- namely: compositional query patterns.

## Compositional Query Patterns

A pattern that I've seen in the wild, and have historically advocated for, is this following pattern:

```elixir
defmodule MyApp.Accounts do
  alias MyApp.Accounts.User
  alias MyApp.Repo

  def count_users(org_id) do
    User
    |> User.where_not_deleted()
    |> User.where_org_id(org_id)
    |> Repo.aggregate(:count)
  end

  def list_users(org_id) do
    User
    |> User.where_not_deleted()
    |> User.where_org_id(org_id)
    |> Repo.all()
  end

  def get_user(org_id, user_id) do
    User
    |> User.where_not_deleted()
    |> User.where_org_id(org_id)
    |> Repo.get_by(id: user_id)
  end
end
```

The main reason you might want to do this is query reuse. If you have a bunch of queries that are very similar, you can build them up in a composable way and reuse them across your application, reducing duplication and making your codebase more maintainable.

However, there are a few problems with this pattern:

1. It's a lot of boilerplate. You have to define a function for each filter you want to apply to your query.
2. It's not very flexible. If you want to add a new filter, you have to define a new function, and remember to add it to every query that needs it.
3. It's not very composable. If you want to reuse a query in a different context, you still have to copy and paste a bunch of boilerplate -- you're not _really_ getting rid of anything here.

So, while this pattern is useful, if not better, it's definitely still somewhat a leaky abstraction. We can do better!

## Metaprogramming to the Rescue

Another one of Elixir's superpowers is metaprogramming. Now, the actual metaprogramming here is optional, but it's a pretty cool way to solve the problems we've outlined above.

> We started doing this without any macros and it still worked.
>
> We iterated on this pattern until we felt comfortable with it, and then we started using macros to:
>
> - Reduce boilerplate
> - Increase consistency
> - Reduce the likelihood anyone would accidentally break the pattern
>
> You can definitely omit the macros and still get a lot of value from this pattern. We did!

Elixir gives us a few useful tools we can use to build a simple composition query abstraction, namely: `behaviours`, `callbacks`, and `macros`.

Let's start by defining a behaviour which we can use to define our queryable schemas:

```elixir
defmodule MyApp.Queryable do
  @callback query(Ecto.Query.t(), Keyword.t()) :: Ecto.Queryable.t()
end
```

This behaviour defines a single callback `query/2` which takes an `Ecto.Query.t()` and a `Keyword.t()` and returns an `Ecto.Queryable.t()`.

> Note: A `behaviour` is a way to define a set of functions that a module must implement. If a module implements a behaviour, it must define all the functions defined in the behaviour.
>
> Basically just an interface. The terminology comes from `erlang` which I'm pretty sure predates the term `interface`.

Any schema that wants to be queryable should implement this behaviour. Let's define a simple queryable schema:

```elixir
def MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Query

  alias MyApp.Entities.Org
  alias __MODULE__

  @behaviour MyApp.Queryable

  schema do
    field :id, :integer
    field :name, :string
    field :password, :string
    field :deleted, :boolean

    belongs_to :org, Org
  end

  def changeset(%User{} = user, attrs) do
    cast(user, attrs, [:name, :password, :boolean, :org_id])
  end

  @impl MyApp.Queryable
  def query(base_query \\ User, opts) do
    # somehow build queries...
  end
end
```

Now we just need to worry about the implementation of the callback itself.

Recall that queries are really just data structures! Elixir gives us a bunch of tools to manipulate data structures, so we can build a simple function that takes a query and a keyword list and applies the filters to the query:

```elixir
@impl MyApp.Queryable
def query(base_query \\ User, opts) do
  Enum.reduce(opts, base_query, fn
    {:id, id}, query when is_integer(id) ->
      from [user: user] in query, where: user.id == ^id

    {:org_id, org_id}, query when is_integer(org_id) ->
      from [user: user] in query, where: user.org_id == ^org_id

    {:name, name}, query when is_binary(name) ->
      from [user: user] in query, where: user.name == ^name
  end)
end
```

This function takes a base query (which defaults to the `User` schema), and a keyword list of filters. It then reduces over the filters and applies them to the query.

Now we can use this queryable schema in our context functions:

```elixir
defmodule MyApp.Accounts do
  alias MyApp.Accounts.User
  alias MyApp.Repo

  def count_users(org_id) do
    Repo.aggregate(User.query(org_id: org_id, deleted: true), :count)
  end

  def list_users(org_id) do
    Repo.all(User.query(org_id: org_id, deleted: true))
  end

  def get_user(org_id, user_id) do
    Repo.one(User.query(id: user_id, org_id: org_id, deleted: true))
  end
end
```

This pattern is a lot more flexible and composable than the previous pattern:

- It's less boilerplate. You only need to define the filters once in the schema.
- It's more flexible. You can add new filters to the schema without changing any of the context functions.
- Like the previous composition pattern, we're co-locating our query logic with the database implementation, which is a good thing when you're building queries _for said database._

### A Little Bit of Magic

Now that we've got a basic compositional query pattern, we can start to build on top of it. One of the things we can do is add some magic to our queryable schemas to further reduce boilerplate and increase consistency.

We noticed that we generally always want to be able to query based on the values of our schema fields. This isn't _all_ we need, but it's a good start.

We added a function in our `MyApp.Queryable` module that we delegate to in our `query/2` callback:

```elixir
defmodule MyApp.Queryable do
  @callback query(Ecto.Query.t(), Keyword.t()) :: Ecto.Queryable.t()

  @spec apply_filter(Ecto.Query.t(), field :: atom(), value :: any()) :: Ecto.Queryable.t()
  def apply_filter(query, field, value) do
    from(x in query, where: field(x, ^field) == ^value)
  end
end
```

Which we can then use in our queryable schemas like so:

```elixir
@impl MyApp.Queryable
def query(base_query \\ User, opts) do
  Enum.reduce(opts, base_query, fn
    {:has_email, true}, query ->
      from x in query,
        as: :user,
        where: exists(from e in Email, where: e.user_id == parent_as(:user).id)

    {field, value}, query ->
      apply_filter(query, field, value)
  end)
end
```

> In reality, my current job's `apply_filter/3` function is a bit more complex than this, but this is the basic idea.
>
> We extended the logic to be able to handle things like:
> - Preloading associations
> - Sorting
> - Pagination
> - Implementing date and datetime filters
> - Implementing `like` or `ilike` filters if the `value :: Regex.t()`
> - Implementing `in` filters if the `value :: [any()]`
> - Implementing simple boolean and mathy-operator filters such as `{:not, term()}` or `{:>, term()}`

Note that we still implement anything _specific_ to our schema in the `query/2` callback, but we can now delegate anything we don't want to write ourselves to the `apply_filter/3` function.

This is a small change, but it makes our queryable schemas even more powerful and flexible.

### Rolling it Out

Once we started implementing this behaviour everywhere, we agreed that this was how we wanted to write queries going forward.

We noticed the following things in our usage:

1. We almost always passed in a `base_query` (which is optional). Generally it would be the schema we were querying on with a `deleted: false` applied.
2. A lot of our queries never needed any custom logic and could be implemented with the `apply_filter/3` function entirely.

This led us to write a macro to automate this base case for us!

```elixir
defmodule MyApp.Queryable do
  defmacro __using__(_opts \\ []) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset
      import Ecto.Query

      import unquote(__MODULE__)

      @behaviour unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def base_query do
        base_query = from x in __MODULE__, as: :self

        if :deleted in __schema__(:fields) do
          from x in base_query, where: x.deleted == false
        else
          base_query
        end
      end

      @impl unquote(__MODULE__)
      def query(base_query \\ base_query(), filters) do
        Enum.reduce(filters, base_query, fn {field, value}, query ->
          apply_filter(query, field, value)
        end)
      end

      defoverridable query: 1, query: 2, base_query: 0
    end
  end

  @optional_callbacks base_query: 0
  @callback query(base_query :: Ecto.Queryable.t(), Keyword.t()) :: Ecto.Queryable.t()
```

This automatically injects the code inside the `quote` block into a function that calls `use MyApp.Queryable`. This means that any schema that uses this module will automatically get the `base_query/0` and `query/2` functions implemented for them.

> Note: The `defoverridable` macro is used to tell Elixir that the `query/2` and `base_query/0` functions can be overridden by the schema that uses this module.
>
> This is useful if you want to add custom logic to your queryable schemas. You can then fall back to the overridden implementation via `super/0` if needed.

## Additional Benefits

We heavily rely on [Absinthe](https://absinthe-graphql.org) for our GraphQL API. We've found that this pattern of queryable schemas has a few additional benefits when used in conjunction with Absinthe.

Typically, when you write a resolver, everything's great because you end up just delegating business logic to some core context function, which can follow whatever patterns you've subscribed to for your application.

However, you can't _just_ have resolvers without running into N+1 problems.

To solve this, we use [Dataloader](https://hexdocs.pm/dataloader/Dataloader.html) to batch our queries. This means that we can load all the data we need in a single query, rather than making a query for each item in a list.

However, this is traditionally done via the implementation of a seperate `MyAppWeb.Loader` module, which looks something like this:

```elixir
defmodule MyAppWeb.Loader do
  def query(MyApp.Billing.Payment = query, args) do
    limit = Map.get(args, :limit)
    offset = Map.get(args, :offset)
    sort = Map.get(args, :sort, :asc)
    ...

    MyApp.Billing.Payment
    |> MyApp.Billing.Payment.paginate(limit, offset)
    |> MyApp.Billing.Payment.sort(sort)
    |> ...
  end
end
```

This is problematic for two reasons:

1. We're duplicating our query logic between our queryable schemas and our loader functions.
2. We're leaking implementation details from our core context into our web layer -- I strongly believe that querying logic is business logic and should be kept in the core context.

However, note the API that Dataloader expects; it expects a function that takes a schema and a set of arguments and returns a query. This is _exactly_ what our `query/2` callback does!

We were able to extend our `MyApp.Queryable` module to include a function that checks if a schema implements the `MyApp.Queryable` behaviour:

```elixir
@spec implements_behaviour?(module :: atom()) :: boolean()
def implements_behaviour?(module) do
  behaviours =
    module.module_info(:attributes)
    |> Enum.filter(&match?({:behaviour, _behaviours}, &1))
    |> Enum.map(&elem(&1, 1))
    |> List.flatten()

  __MODULE__ in behaviours
end
```

And in our loader, we can now do the following:

```elixir
defmodule MyAppWeb.Loader do
  def query(module, args) do
    if MyApp.Queryable.implements_behaviour?(module) do
      module.query(args)
    else
      raise "Dataloader relations must implement the `MyApp.Queryable` behaviour."
    end
  end
end
```

This means that we can now use our queryable schemas in our Dataloader functions, and we don't have to duplicate our query logic between our core context and our web layer. You've got a single source of truth for your query logic, and you're not leaking implementation details from your core context into your web layer.

Now, arguably, this relies on your GraphQL schema mapping closely to your database schema, but in our experience, this is generally the case.

If you need to do something more complex, you can always fall back to the traditional way of writing your loader functions.

## Conclusion

Ecto queries are just data structures, and we can leverage this to build powerful compositional query patterns that reduce boilerplate, increase consistency, and make our code more maintainable.

By using behaviours, callbacks, and macros, we can build a simple compositional query pattern that allows us to define our query logic in our queryable schemas and reuse it across our application.

This pattern has been used so much, and has been so successful at my current job, that we've open-sourced our implementation in a library called [EctoModel](https://hex.pm/packages/ecto_model). It comes with a few additional things, but you can both see the core pattern we use as well as how we've extended it.

If you try to use `ecto_model`, you have to opt into any of the bits of functionality provided, so you'll need to define a `MyApp.Queryable` module that uses `EctoModel.Queryable`.

As an aside, we've also leveraged this queryable pattern as a way of building fluent APIs with `Keyword.t()`s.

For example, with [Endo](https://hex.pm/packages/endo), we've built a way to build queries like so:

```elixir
iex> Endo.list_tables(MyApp.Repo, with_column: "user_id", without_index: "user_id", without_columns: ["inserted_at", "updated_at"])
[
  %Endo.Table{},
  ...
]
```

This is a bit more complex, but the core idea is the same: build queries as data structures and compose them in a functional way, leveraging `ecto` or not!

All of this is ultimately possible because Elixir providers great tools for building abstractions, patterns, and working with data!

Happy hacking!
