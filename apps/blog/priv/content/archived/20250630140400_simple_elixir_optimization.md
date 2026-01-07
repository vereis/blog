---
title: Simple Elixir Optimization
slug: simple-elixir-optimization
is_draft: false
reading_time_minutes:
published_at: 2025-06-30 14:04:00Z
description: |
  Coming from other languages, especially imperative ones, it's easy to write suboptimal Elixir code.

  This post covers practical optimizations—avoiding `length/1`, leveraging streaming, using ETS—without needing complex profiling tools.
tags:
  - elixir
---

We all know that feeling when you get that bug report... "This new feature is so slow!", or you notice your unit tests are taking longer than expected.

I ran into this last week while pairing with a new engineer in my team, and I was able to point out a few simple optimizations that made a **huge** difference in the performance of our new code.

Without diving deep into the rabbit hole of complex profiling tools, I wanted to share some simple tips that can help you optimize your Elixir code quickly and effectively.

> If you  **are** interested in more advanced profiling tools and techniques, I'd recommend looking at:
> - `:observer` which is a nice GUI tool for introspecting your Elixir/Erlang applications.
> - `:eprof`, `:fprof`, and `:cprof` which are Erlang's built-in profiling tools for function/call profiling.
> - [benchee](https://github.com/bencheeorg/benchee) for benchmarking code.
> - [recon](https://github.com/ferd/recon) provides tooling for diagnosing issues in production systems.
> - [erlyberly](https://github.com/andytill/erlyberly) simple GUI for tracing.

## Sequential Elixir

Most of the time, when we write Elixir code, we are writing **sequential Elixir**.

This means that the code we're writing is inherently sequential, and we are not taking advantage of Elixir's concurrency features. This is a totally valid way to write code, and it is often the simplest way to get things done.

However, due to the functional nature of Elixir, there might be a lot of footguns that can be avoided to make your code run faster.

> The footguns are stupidly easy to run into if you're not aware of how the BEAM works.

Here are some tips to help you write more efficient sequential Elixir code.

### Unexpectedly Expensive Operations

#### Calculating Length of Lists

A common pitfall people run into is writing code like this:

```elixir
def process_items(items) when length(items) > 1 do
  ...
end

def process_items(items) do
  ...
end
```

This code looks fine and simple at a glance, but it has a hidden performance issue.

Unlike other languages like JavaScript, calculating the length of a list in Elixir is **not cheap**.

In most languages, the length of a list is stored as a property **on that list**. This means that you can access the length of a list in constant time, `O(1)`.

In Elixir, however, all lists are linked lists, and the length of said list is not stored as a property anywhere.

This means that calculating the length of a list in Elixir is an `O(n)` operation, where `n` is the number of elements in the list.

> Lists are implemented like Lisp cons cells, where each cell contains a value and a pointer to the next cell.
>
> This means that to calculate the length of a list, you have to traverse the entire list, which takes linear time.

This means that the code above will have a performance issue when the list is large, because it will have to traverse the list entirely to calculate the length of the list every time it is called.

Instead of using `length/1`, you can use pattern matching to check if the list is empty or has more than one element:

```elixir
def process_items([]) do
  ...
end

def process_items([_ | _] = items) do
  ...
end
```

#### String Concatenation

Another common pitfall is string concatenation.

In standard Erlang, strings are implemented as lists of characters, which means that concatenating two strings is an `O(n)` operation, where `n` is the length of the first string.

In Elixir, however, strings are implemented as binaries, which means that concatenating two strings is an `O(1)` operation.

The problem is that despite this being an `O(1)` operating, string concatenation creates a **new binary** every time you concatenate two strings.

This means that if you concatenate a lot of strings, you will end up with a lot of memory being allocated, which can lead to performance issues.

One of the cool things about the BEAM is that most string operations don't only work on strings or binaries, but also on something called an `IOList`.

In short, an `IOList` is a list containing:

- Binaries like `<<"Hello">>` in Erlang or `"Hello"` in Elixir.
- Strings (charlists) like `"Hello"` in Erlang or `~c"Hello"` in Elixir.
- Other `IOList`s.

List processing (outside of calling `length/1` per the above section) are generally quite optimized.

One such optimization is that concatenating lists is an `O(1)` operation, because it just creates a new list that points to the original lists.

Because of this, and the fact that `IOList`s are treated as a "single unit" when passed to functions like `IO.puts/1`, `IO.inspect/1`, or `IO.write/1`, you can use `IOList`s to concatenate strings without creating a new binary every time.

In fact, Phoenix's [templating](https://hexdocs.pm/phoenix/Phoenix.HTML.html) does this under the hood when rendering your templates and it works **extremely well**.

Instead of doing:

```elixir
iex> :ok =
...>   x
...>   |> Enum.reduce(x, "", fn i, acc -> acc <> i.name <> "," end)
...>   |> IO.puts()
"Hello,World,Elixir"
```

You can do:

```elixir
iex> :ok =
...>   x
...>   |> Enum.map(& &1.name)
...>   |> Enum.join(",")
...>   |> IO.puts()
"Hello,World,Elixir"
```

> I'd recommend looking at the following resources to learn more about `IOList`s:
> 1. [Elixir Patterns](https://github.com/gar1t/erlang-patterns/blob/master/patterns/iolist.md)
> 2. [High Perf. String Processing](https://www.youtube.com/watch?v=Y83p_VsvRFA)

Since `IOList`s are just lists, you'll benefit from the following optimization also.

#### List Concatenation

While list concatenation **can be** an `O(1)` operation, it is unfortunately only the case when you concatenate lists in a specific way.

When you concatenate two lists manually, like this:

```elixir
iex> list = [4, 5, 6]
iex> [1, 2, 3 | list]
[1, 2, 3, 4, 5, 6]
```

This is an `O(1)` operation, because it just creates a new list that points to the original lists.

The `[1, 2, 3]` list would have to be created no matter what, but the `[4, 5, 6]` list is just a pointer to the original list.

> To generalize, list concatenation is `O(1)` for the `RHS` of the `|` operator, but `O(n)` for the `LHS`.

However, most people won't concatenate lists like this without knowing about it, and will instead use:

- The `++` operator.
- Functions like `Enum.concat/1` or `List.flatten/1`.

For example:

```elixir
Enum.reduce(items, [], fn item, acc ->
  acc ++ [process(item)]
end)
```

This feels very natural, but this is actually a hidden `O(n)` operation for the `LHS` of the `++` operator.

Instead of doing this, it's often faster to build lists via appending items on the `LHS` (i.e. building lists in reverse) and then reversing the list when you need it:

```elixir
items
|> Enum.reduce([], fn item, acc -> [process(item) | acc] end)
|> Enum.reverse()
```

This technically ends up being `O(n)` in total, but it avoids the hidden `O(n^2)` performance issue of the `++` operator.

### Regex Compilation

Regular expressions in Erlang and Elixir are interesting because they can be run in two modes:

- **Compiled**: The regex is compiled into a form that can be executed quickly.
- **Uncompiled**: The regex is interpreted directly from the string.

Compiled regexes are much faster than uncompiled regexes, but they require a bit more setup.

Instead of doing the following, which compiles the regex every time it is called:

```elixir
def extract_emails(text) do
  Regex.scan(~r/\w+@\w+\.\w+/, text)
end
```

You can simply compile the regex once and reuse it:

```elixir
@email_regex ~r/\w+@\w+\.\w+/
def extract_emails(text) do
  Regex.scan(@email_regex, text)
end
```

> The `@` syntax is a module attribute. Basically, it's a way to define constants which are evaluated at compile time.

### File IO

File IO in Elixir is generally quite fast, especially building on top of the previous tips, but there are a few things you can do to make it even faster.

The [File](https://hexdocs.pm/elixir/File.html) module provides a lot of functions for reading and writing files, but there are some lesser-known functions that can help you optimize your file IO.

For example, instead of using `File.read/1` to read a file, you can use `File.stream!/1` to read the file in chunks.

> We'll talk about this later in detail, so I won't go into too much detail here.

Additionally, you can refactor multiple `File.write/3` calls into a `File.open/3` call instead:

Instead of doing this:

```elixir
Enum.each(lines, fn line ->
  File.write("log.txt", line, [:append])
end)
```

You can do this which might batch writes (I believe this depends on the underlying filesystem), but keeps the file open for the duration of the writes:

```elixir
File.open("log.txt", [:write], fn file ->
  Enum.each(lines, &IO.write(file, &1))
end)
```

### Enum Operations

One of the most common modules people will use in Elixir is the [Enum](https://hexdocs.pm/elixir/Enum.html) module.

Unfortunately, it's also one of the most common places where people run into performance issues.

One of the most common performance issues I see is inefficient use of `Enum` functions, especially in the following ways.

#### Multiple Passes

This one can be a readability tradeoff, but each `Enum` function will iterate over the collection, which can lead to multiple passes over the data.

Instead, you can often write your code using `Enum.reduce/3` to iterate over the collection once and perform multiple operations in a single pass.

In short, instead of:

```elixir
data
|> Enum.filter(&valid?/1)
|> Enum.map(&transform/1)
|> Enum.sort()
```

You can do:

```elixir
data
|> Enum.reduce([], fn item, acc ->
  if valid?(item) do
    [transform(item) | acc]
  else
    acc
  end
end)
|> Enum.sort()
```

There are also helper functions in `Enum` which collapse multiple operations into a single pass such as:

- `Enum.flat_map_reduce/3` which combines `flat_map/2` and `reduce/3`.
- `Enum.map_reduce/3` which combines `map/2` and `reduce/3`.
- `Enum.min_max/2` which combines `min/2` and `max/2`.
- `Enum.min_max_by/2` which combines `min_by/2` and `max_by/2`.

There are also functions which will terminate iteration early, such as:

- `Enum.any?/2` which checks if any element in the collection satisfies a condition.
- `Enum.all?/2` which checks if all elements in the collection satisfy a condition.
- `Enum.reduce_while/3` which allows you to stop iteration early based on a condition.

These can be especially helpful if you're iterating over a large collection and only need to check a condition or perform a single operation.

#### Nested Operations

Some code I reviewed recently had a lot of code that looked like this:

```elixir
users
|> Enum.map(fn user ->
  department = Enum.find(departments, &(&1.id == user.department_id))
  %{user | department: department}
end)
```

The problem with this is that this is an `O(n²)` operation, because for each user, it has to iterate over the entire list of departments to find the matching department.

Oftentimes when I run into code that looks like this, you can refactor the code to "lift" the nested `Enum.find/2` operation out of the loop and use a map to look up the department by ID instead.

This ends up looking like:

```elixir
department_map = Map.new(departments, &{&1.id, &1})

users
|> Enum.map(fn user ->
  department = Map.get(department_map, user.department_id)
  %{user | department: department}
end)
```

This is an `O(n)` operation, because it only has to iterate over the list of departments once to build the map, and then it can look up the department by ID in constant time.

> If you take anything away from this article, it's that you should **always** lift nested operations out of loops when possible.
>
> We'll build on top of this idea later.

#### Using the Wrong Function

Another common pitfall is using the wrong function for the job.

The `Enum` module provides **a hell of a lot of utility**, but as a result, it can be easy to overly rely on it.

One very common example of this is using `Enum.member?/2` or the `in` operator to check if a value is in a list, which is an `O(n)` operation.

Instead, Elixir provides a `MapSet` module which provides a set data structure that allows you to check if a value is in the set in constant time, `O(1)`.

You can often refactor code that looks like this:

```elixir
allowed_statuses = ["active", "pending", "verified"]
items |> Enum.filter(fn item -> item.status in allowed_statuses end)
```

Into this:

```elixir
allowed_statuses = MapSet.new(["active", "pending", "verified"])
items |> Enum.filter(fn item -> MapSet.member?(allowed_statuses, item.status) end)
```

This is especially useful inside of loops, where you might be checking if a value is in a list multiple times.

### Batch Processing

Another common pitfall I see all the time is processing data one element at a time.

This is a natural result of the way we write code.

It's totally normal to write code that initially looks like this:

```elixir
def create_activity(attrs) do
  %Activity{}
  |> Activity.changeset(attrs)
  |> Repo.insert()
end
```

But sometime in the future, you might find yourself needing to create a lot of activities at once, and you'll end up writing code that looks like this:

```elixir
def create_activities(attrs_list) do
  Enum.each(attrs_list, &create_activity/1)
end
```

This is a common pattern, but it can lead to performance issues, especially if you're creating a lot of records at once because you end up doing `N` database calls, where `N` is the number of records you're creating.

This isn't exclusively a problem with database calls, but can be an issue with any expensive operations whose runtime is proportional to the number of items you're processing.

While it might be a bit of a case of premature optimization (especially for the `create_activity/1` example), I often try to write my code in a batch-first way.

For the above example, I might write the code to initially look like this instead:

```elixir
def create_activity(attr) do
  attr
  |> List.wrap()
  |> create_activities()
  |> List.first()
end

def create_activities(attrs_list) do
  attrs_list
  |> Enum.map(&Activity.changeset(%Activity{}, &1))
  |> Repo.insert_all()
end
```

This way, I can still call `create_activity/1` with a single attribute, but I can also call `create_activities/1` with a list of attributes to create multiple activities at once.

All of this, using the same single source of truth!

You can do a little better than this though! Oftentimes functions will start to hit other performance issues when you start to process large amounts of data at once.

But the nice thing about building your business logic functions in a batch-first way is that you can trivially start to process data in batches without having to rewrite your code, see:

```elixir
def create_activities(attrs_list) do
  attrs_list
  |> Enum.chunk_every(1000)
  |> Enum.flat_map(fn chunk -> do_create_activities(chunk) end)
end
```

> I admit the example above is a bit contrived, but the idea is that you can build your code in a way that allows you to process data in batches without having to rewrite your code.

### Streaming

Another issue I've seen happen related to the previous section is that people will often try to process large amounts of data in memory at once.

This might be totally fine, especially for local development because you've got your entire development machine's worth of RAM available.

On a production, that isn't always the case, especially if you're getting a lot of traffic and your application is running on a small instance.

This is where **streaming** comes in.

Streaming is a way to process data in chunks, without having to load the entire dataset into memory at once.

Elixir provides a lot of great tools for streaming data, such as the `Stream` module and the `File.stream!/1` function.

Other libraries such as [Ecto](https://hexdocs.pm/ecto/) also provide streaming capabilities for database queries which I find extremely useful.

Part of my team's main responsibilities is running analytics and reporting for veterinary clinics, and oftentimes we're working with years worth of data for thousands of patients across hundreds of clinics.

It goes without saying that trying to `Repo.all(query)` our way through that data is a **terrible** idea, and we instead use `Repo.stream(query)` to process the data in chunks.

Streaming is also great for processing large files, such as CSVs or JSON files, without having to load the entire file into memory at once.

Instead of doing something like this:

```elixir
def generate_csv_report do
  users = Repo.all(User)  # Could be millions of records!
  csv_data = Enum.map(users, &format_user_row/1)
  File.write("report.csv", csv_data)
end
```

You can simply swap it out for:

```elixir
def generate_csv_report do
  Repo.transaction(fn ->
    File.open("report.csv", [:write], fn file ->
      User
      |> Repo.stream()
      |> Stream.map(&format_user_row/1)
      |> Enum.each(&IO.write(file, &1))
    end)
  end)
end
```

This way, you can process the data in chunks, without having to load the entire dataset into memory at once. You're also writing the data to the file as you go, which means you don't have to keep the entire CSV in memory either.

Many libraries that work with files also provide streaming capabilities, such as [CSV](https://hexdocs.pm/csv/) and [Packmatic](https://hexdocs.pm/packmatic/).

## Concurrent Elixir

Once your sequential code is optimized, this is the point where I'd start thinking about if I could leverage Elixir's concurrency features to further improve performance.

The heuristic I use is simple and non-exhaustive: **if you're working with data which doesn't depend on other elements in the collection, and you're already batching or streaming, you can probably parallelize it**.

### Task.async_stream/2

Elixir provides a `Task.async_stream/2` function which can be seen almost like a drop-in replacement for `Enum.map/2` that runs a given transformation function concurrently across elements in the input collection.

For example, instead of doing this:

```elixir
users
|> Enum.map(&fetch_user_details/1)
```

You can usually just replace the `Enum.map/2` call with the following:

```elixir
users
|> Task.async_stream(&fetch_user_details/1)
|> Enum.map(&elem(&1, 1))
```

This will run the `fetch_user_details/1` function concurrently across all users, and return a list of results.

If you've already leveraged batching and/or streaming optimizations, you can also use `Task.async_stream/3` to process the data in chunks concurrently, which can further improve performance:

```elixir
users
|> Enum.chunk_every(@chunk_size)
|> Task.async_stream(&fetch_user_details/1)
|> Enum.flat_map(&elem(&1, 1))
```

There are a few footguns to be aware of when using `Task.async_stream/2`, such as:

- Doing operations concurrently results in more memory being used.
- Default concurrency is set to the number of schedulers available on the system, which is usually the number of CPU cores. This can be too much but can be adjusted with the `:max_concurrency` option.

More importantly, one big footgun for using multiple processes in Elixir is general is that you need to be careful about **shared state**.

In the `Enum` example, the transformation function (or really any lambda) has access to the variables in the surrounding scope and generally speaking, there's no real cost to accessing those variables.

But when you start using multiple processes, you need to be careful. Lambdas still have access to the surrounding scope, but if you recall: processes do not share memory in the BEAM.

What this boils down to is that if you try to access a variable in the surrounding scope, it will be copied into the process's memory space, which can lead to performance issues if you're accessing large data structures.

I accidentally ran into this by trying to parallelize a function that was reading data out of a "lifted" map for fast lookups. The map was large, and the act of copying it into each process's memory space caused our BEAM instances to run out of memory.

This is a common footgun. Thankfully, Elixir provides a simple way to avoid this.

### ETS Tables

Erlang ships with a powerful in-memory data structure called **ETS** (Erlang Term Storage) which allows you to store large amounts of data in memory and access it quickly.

You can think of it as an in-memory key-value store that is shared between processes, and it is extremely fast.

> If I remember correctly, ETS lookups are `O(1)` operations, and inserts are `O(log n)` operations.
>
> They can also be tuned to maximize concurrent reads and writes, which is extremely useful for high-performance applications.

There are multiple types of ETS tables:

- **Set**: A table that stores unique values.
- **Ordered Set**: A table that stores unique values in the order they were inserted.
- **Bag**: A table that allows duplicate values.
- **Duplicate Bag**: A table that allows duplicate values and maintains the order they were inserted.

> I've often abused `:bag` and `:duplicate_bag` ETS tables to sidestep needing to write deduplication or grouping logic elsewhere in my pipelines.
>
> This might not be **efficient** (though maybe it is), but it does make the surrounding code simpler and easier to read.

You can check out some basic ETS usage as follows:

```elixir
# Create and populate table
:ets.new(:lookup, [:set, :public, :named_table])
Enum.each(departments, fn dept ->
  :ets.insert(:lookup, {dept.id, dept})
end)

# Fast lookups across processes (no copying)
items |> Task.async_stream(fn item ->
  [{_key, dept}] = :ets.lookup(:lookup, item.department_id)
  process(item, dept)
end)
```

Using ETS tables this way in lieu of "lifting up" maps or other data structures is that you can avoid the performance issues of copying large data structures into each process's memory space, and you can also take advantage of the concurrent read/write capabilities of ETS tables.

> ETS also provides powerful querying capabilities built on top of pattern matching.
>
> I won't talk too much about this here as it's besides the scope of this article.
>
> Do check out [Etso](https://hexdocs.pm/etso/) which lets you use `Ecto` to query ETS tables as though it were a standard Postgres or SQLite database.

ETS tables, by default, are owned by the process that created them, but they can be made **public** so that other processes can access them. When the owner process dies, the ETS table is automatically deleted.

This is configurable, but again, that's beyond the scope of this article.

One of the annoying things about ETS tables is that the API around them is a bit clunky. This is something I can live with, but in many of my own projects, I've created a simple wrapper around ETS tables to make them easier to use.

I'll often create something like this which mimics the `Map` API:

```elixir
defmodule Utils.ETS do
  @type type :: :set | :ordered_set | :bag | :duplicate_bag

  @spec new(type :: type()) :: :ets.table()
  def new(type \\ :set) do
    :ets.new(__MODULE__, [type, :public, write_concurrency: true, read_concurrency: true])
  end

  @spec put(:ets.table(), term(), term()) :: :ets.table()
  def put(table, key, value) do
    :ets.insert(table, {key, value})
    table
  end

  @spec get(:ets.table(), term(), term()) :: term()
  def get(table, key, default \\ nil) do
    type = type(table)

    case :ets.lookup(table, key) do
      [] ->
        default

      [{^key, value}] when type == :set ->
        value

      [{^key, _value} | _rest] = values when type == :duplicate_bag ->
        Enum.map(values, &elem(&1, 1))
    end
  end

  @spec has_key?(:ets.table(), term()) :: boolean()
  def has_key?(table, key) do
    :ets.member(table, key)
  end

  @spec from_list(list()) :: :ets.table()
  def from_list(enum) do
    table = new()
    for {key, value} <- enum, do: put(table, key, value)
    table
  end

  @spec to_list(:ets.table()) :: list()
  def to_list(table) do
    raw_list = :ets.tab2list(table)

    case type(table) do
      :duplicate_bag ->
        raw_list |> Enum.group_by(&elem(&1, 0), &elem(&1, 1)) |> Enum.to_list()

      _otherwise ->
        raw_list
    end
  end

  @spec type(:ets.table()) :: type()
  defp type(table), do: :ets.info(table, :type)
end
```

### Flow

Sometimes, instead of wanting to use `Task.async_stream/2` because your pipeline is more complex, you might want to use a more powerful tool like [Flow](https://hexdocs.pm/flow/).

Flow is a library built on top of [GenStage](https://hexdocs.pm/gen_stage/GenStage.html) by Jose Valim that provides a way to process data in parallel manner.

The `Flow` module provides a lot of functions similar to the `Enum` or `Stream` modules, and depending on your setup, it gives you advanced features like:

- **Backpressure**: Flow can automatically adjust the number of concurrent processes based on the amount of data being processed.
- **Partitioning**: Flow can partition the data into multiple stages, allowing you to process data in parallel across multiple processes.
- **Windowing**: Flow can group data into windows, allowing you to process data in batches.

This is especially useful for processing large datasets, such as logs or analytics data, where you want to process the data in parallel without having to load the entire dataset into memory at once.

The same caveats apply as with `Task.async_stream/2`, such as being careful about shared state and memory usage, but Flow provides a lot of powerful features that can help you process data in parallel efficiently.

You can check out the [Flow documentation](https://hexdocs.pm/flow/Flow.html) for more information on how to use it, but a simple example looks like:

```elixir
large_dataset
|> Flow.from_enumerable(max_demand: 500)
|> Flow.partition(key: {:key, :department_id})
|> Flow.reduce(fn -> %{} end, fn item, acc ->
  # Stateful operations per partition
end)
|> Flow.map(&expensive_transformation/1)
|> Flow.run()  # Blocks until complete
```

## Distributed Elixir

Once you've optimized your sequential and concurrent Elixir code, you might want to take advantage of Elixir's distributed capabilities.

Distributed Elixir is a powerful feature that allows you to run your Elixir applications across multiple nodes, which can help you scale your application horizontally.

One of the problems with distributed Elixir is that it can be a bit complex to set up, and it requires a bit of knowledge about how the BEAM works.

Thankfully, you can sometimes sidestep all this complexity by using libraries that provide distributed capabilities out of the box.

### Oban

At my day job, we use [Oban](https://oban.pro/) to run background jobs across multiple nodes, and it provides a lot of powerful features (especially with `Oban.Pro`) such as:

- **Batched Jobs**: Oban can insert jobs in batches, and provide callbacks for when jobs are completed.
- **Queue Control**: Different nodes can start run different queues, and Oban will automatically distribute jobs across the nodes.
- **Workflows**: Jobs can form a directed acyclic graph (DAG) of dependencies, allowing you to run jobs in parallel and control the order in which they are executed.
- **Relay**: Let's you `await` job completion, allowing you to mimic the behavior of `Task.async_stream/2` and friends.

I have the perfect example of this in my day job.

We have a subsystem which is responsible for sending health reminders for patients. These health reminders need to be generated in one of two ways:

- **Demand**: We can generate health reminders for a single patient.
- **Bulk**: We can generate health reminders for all patients in a clinic.

We've written our business logic in such a way that the "runtime" of the subsystem is abstracted away from the business logic.

For the "on-demand" case, we pass our callbacks into a `Task.async/2` and `Task.await/2` based runtime:

```elixir
def demand(%Protocols.Scope{org_id: org_id} = scope, opts) do
  dag = Engine.build_dag(scope)

  :ok =
    Enum.each(dag, fn
      dag_stages when is_list(dag_stages) ->
        dag_stages
        |> Enum.map(&Task.async(fn -> run_dag_stage(&1, scope) end))
        |> Task.await_many(:timer.minutes(5))

      dag_stage ->
        run_dag_stage(dag_stage, scope)
    end)

  get_result(dag, scope)
end
```

For the "bulk" case, we build an [Oban Workflow](https://getoban.pro/docs/pro/1.1.2/Oban.Pro.Workers.Workflow.html) which automatically distributes the work across multiple nodes, in our case, sharded by veterinary clinic:

```elixir
def bulk(org_id, opts) do
  dag = Engine.build_dag()

  for location <- Entities.list_locations(org_id: org_id) do
    args = %{location_id: location.id, org_id: location.org_id}

    workflow = Worker.new_workflow()

    workflow =
      Enum.reduce(dag, workflow, fn {dag_stage, dependencies}, workflow ->
        args
        |> Map.put(:stage, dag_stage)
        |> Worker.new()
        |> then(fn worker -> Worker.add(workflow, stage, worker, deps: dependencies) end)
      end)

    Oban.insert_all(workflow)
  end

  :ok
end
```

This way, we can run the same business logic in both cases, but the "bulk" case is distributed across multiple nodes, allowing us to scale horizontally.

A similar pattern can be used for [Batch Workers](https://getoban.pro/docs/pro/1.1.2/Oban.Pro.Workers.Batch.html) which instead of taking a DAG of jobs that need to be run, take a list of items that need to be processed in parallel.

Each batch worker simply processes each item in the batch concurrently, and you can use the same business logic as before.

When batches are completed, the provided `handle_completed/1` callback is called, allowing you to do any post-processing you need to do.

> The code example I have on hand for batches is a lot more complicated than can realistically be shown here, but check out the documentation!
>
> If you ever needed a reason to use `Oban.Pro`, this is it!

Lastly, you can use [Relay](https://getoban.pro/docs/pro/1.1.2/Oban.Pro.Relay.html) to await the completion of a job, which allows you to mimic the behavior of `Task.async_stream/2` and friends, but with the added benefit of being able to run the job across multiple nodes.

### Additional Reading

There's plenty of other approaches to utilizing distributed Elixir, but those tend to be more application-specific so its hard to give general advice.

I'd recommend reading the following resources:

- [Dangers of the Single Global Process](https://keathley.io/blog/sgp.html)
- [Distributed Elixir Documentation](https://elixir-lang.org/getting-started/mix-otp/distributed-tasks-and-configuration.html)
- [FLAMe: A Distributed Profiler](https://github.com/AdRoll/flame)

One of the footguns people run into with distributed Elixir is that BEAM distribution is:

1. A fully connected mesh network of nodes.
2. Nodes keep track of all other nodes in the network.
3. Nodes send periodic heartbeats to each other to ensure they are still alive.
4. Nodes send messages to eachother for communication.

There are two problems with this (standard `netsplit` problem aside):

1. If you have too many nodes, the heartbeat chatter can overwhelm the network and cause performance issues.
2. A node has a single process responsible for handling RPC messages, so large or frequent messages can overwhelm the node and cause it to crash.
3. Heartbeat messages are just like normal RPC messages, so RPC calls and heartbeats cause contention, leading potentially to crashes.

I've used libraries such as [gen_rpc](https://github.com/priestjim/gen_rpc) which reimplements RPC messages for distributed Erlang/Elixir to be handled via seperate processes listening to TCP/IP sockets, but this is additional complexity.

## Conclusion

Most Elixir performance issues I've seen start with inefficient sequential code.

Fix your `Enum` functions first, make sure you're not running into any footguns, and then start thinking about concurrency.

Once you've done that, maybe think about distributed Elixir, but only if you really need it.

That gives you a **lot** of breathing room to optimize your code **as is** before you start thinking about larger architectural changes.

Remember: premature optimization is still the root of all evil, but when you do need to optimize, having a systematic approach saves time and prevents you from chasing the wrong bottlenecks.
