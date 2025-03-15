---
title: On Streams In Elixir
slug: on_streams_in_elixir
is_draft: false
reading_time_minutes:
published_at: 2025-03-15 17:38:40Z
tags:
  - elixir
---

The standard library that ships with [Elixir](https://elixir-lang.org/) feels very complete and well thought out.

One of the modules that you'll find yourself inevitably getting to know very well is the [Enum](https://hexdocs.pm/elixir/Enum.html) module which provides a lot of functions that work over collections.

The [Stream](https://hexdocs.pm/elixir/Stream.html) module is typically introduced alongside the `Enum` module as in many cases it can be a drop-in replacement for `Enum` functions, but tailored for working with potentially infinite collections.

One of the problems I ran into early on was simply just a lack of understanding of what a `Stream` actually is, and how its so much more than just a lazy `Enum`.

## Enum vs Stream

In Elixir, code like this is very common:

```elixir
iex> [1, 2, 3, 4, 5]
...> |> Enum.map(&(&1 * 2))
...> |> Enum.filter(&(&1 > 5))
...> |> Enum.sum()
24
```

This code will take a list of numbers, double each number, filter out any numbers less than or equal to 5, and then sum the remaining numbers.

For this simple example, using `Enum` functions is perfectly fine. However, if you were to replace `Enum` with `Stream` in the above code, you would see no difference in the output:

```elixir
iex> [1, 2, 3, 4, 5]
...> |> Stream.map(&(&1 * 2))
...> |> Stream.filter(&(&1 > 5))
...> |> Enum.sum()
24
```

Note that the `Enum.sum()` function is still used at the end. This outlines one of the main differences between `Enum` and `Stream` functions.

Any time you call an `Enum` function, the entire input is processed and the output is returned. On the other hand, `Stream` functions accumulate a series of transformations and these transformations are only applied when "run".

Running a `Stream` is done either when `Stream.run/1` is called, or when the `Stream` is passed into an `Enum` function which "realizes" the stream.

> As an important note, when realizing a stream (i.e calling `Enum.to_list/1` or `Enum.sum/1` on a stream), the whole stream is processed and the entire result is saved in memory and returned, which might be an unexpected footgun if you're working with potentially infinite streams.

Additionally, `Stream` functions are lazy, meaning that they only process inputs as needed.

What this means is, if you have a potentially infinite collection, you can write something like this:

```elixir
iex> MyApp.generate_infinite_collection()
...> |> Stream.map(&(&1 * 2))
...> |> Stream.filter(&(&1 > 5))
...> |> Enum.take(5)
[6, 8, 10, 12, 14]
```

In this example, `MyApp.generate_infinite_collection/0` is a function that returns an infinite collection of numbers and the `Stream` functions will only process as many numbers as needed to satisfy the `Enum.take(5)` function.

This deffered processing and laziness is the core of what differentiates `Stream` from `Enum`, and one of the core benefits this gives you is that you're optimizing for memory usage.

## Misconceptions

There are several misconceptions I had, and have heard from others who are unfamiliar with `Stream`, that I'd like to address before continuing:

### Streams are faster than Enums

Unfortunately, using `Stream` over `Enum` won't inherently make your code faster.

In fact, in many cases, `Stream` can be slower than `Enum` due to the overhead of keeping track of the transformations that need to be applied, and applying them.

This is done by wrapping each previous transformation in an anonymous function, and then applying the new transformation to the result of the previous transformation.

For example, the following code might end up being represented thusly:

```elixir
# Elixir Code
iex> 1..10
...> |> Stream.map(&(&1 * 2))
...> |> Stream.filter(&(&1 > 5))
...> |> Stream.map(&(&1 + 1))

# Example Stream Representation
fn ->
  fn ->
    fn -> [1, 2, ..., 10] end
  end
end
```

When this stream is finally realized, each wrapper function has to be invoked per element in your collection, which is marginally slower than just applying the transformations directly.

The reality is that `Stream` functions optimize for memory usage, not speed, though lowering overall memory usage can lead to faster code in some cases due to resource contention.

### Streams execute in parallel

This was something I had assumed when I first began learning Elixir, but this is simply not the case.

When a `Stream` is realized, each transformation is applied in sequence, in the current process, and there is no parallelism or concurrency involved.

However, there are functions such as `Task.async_stream/3` which can be used to parallelize the processing of a stream, but this is something that has to be explicitly done.

```elixir
iex> 1..10
...> |> Task.async_stream(&(&1 * 2), max_concurrency: 5)
...> |> Enum.to_list()
[{:ok, 2}, {:ok, 4}, ...]
```

The above example spawns up to 5 processes at a time to process the stream, each process handling a single element in the stream.

> By default, `Task.async_stream/3` will spawn up to `System.schedulers_online()` processes, which is the number of schedulers available to the BEAM VM.
>
> Each spawned process also has a default timeout of 5 seconds, which can be changed by passing a `timeout` option to `Task.async_stream/3`.

There are also libraries such as [Flow](https://hexdocs.pm/flow/Flow.html) which have an API similar to `Enum` and `Stream`, but are designed to work with parallel processing in mind, which I recommend checking out if you're looking to build large-scale concurrent data processing pipelines.

### Streams operate on collections

Since `Enum` and `Stream` are modules which are introduced alongside each other, and often times used in similar contexts, it's easy to assume that `Stream` functions only work on collections.

However, this is not the case.

`Stream` functions are similar to "generator" functions in other languages, and can be used to generate values on-the-fly, without needing to store them in memory.

This "value generation" can be done using functions such as `Stream.iterate/1`, `Stream.cycle/1`, or `Stream.resource/3`, and can be used to "wrap" many data sources into something that can be easily processed.

For example, Elixir ships with `File.stream!/1` which is a helper function that returns a stream that reads a file line-by-line, `Ecto.Repo.stream/2` returns a stream which fetches rows from a database, etc.

At [Vetspire](https://vetspire.com/), we've even used `Stream.resource/3` to handle fetching data from external APIs, where we have to poll the API to check if any new data is available, and then fetch the data if it is.

## Footguns

Alongside the above misconceptions, there are a few footguns that I've run into when working with `Stream` that I'd like to call out:

### Streams don't return anything

When you call a `Stream` function, it doesn't return anything, it just returns a new stream with the transformation applied.

This can be confusing if you're used to `Enum` functions which return the result of the transformation.

For example, the following code will return a stream, rather than the result of the transformation:

```elixir
iex> 1..10
...> |> Stream.map(&(&1 * 2))
#Stream<[enum: 1..10, funs: [#Function<50.38948127/1 in Stream.map/2>]]>
```

If you want to realize a `Stream`, you _have_ to pass it to an `Enum` function, or call `Stream.run/1`:

```elixir
iex> 1..10
...> |> Stream.map(&(&1 * 2))
...> |> Enum.to_list()
[2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
```

### API inconsistencies between Enum and Stream

This one is less of a footgun, and makes sense when you understand the design of `Stream`, but it might be surprising if you're unfamiliar with `Stream`.

The return value for `Enum.each/2`: it applies the given transformation function to each element in a given collection, but always returns `:ok`.

Semantically, this makes sense because `Enum.each/2` is used for side-effects, and the return value is not important.

However, the equivalent `Stream.each/2` function returns the original stream, which can be surprising if you're not expecting it.

This is actually very ergonomic for building complex stream pipelines, but is one case where `Enum` functions and `Stream` functions can't be used interchangeably.

### Inspecting a stream

Per the above example, because each `Stream` function returns a new stream, it can be difficult to inspect the contents of a stream.

For example, if you run the following code, note what get's printed out:

```elixir
iex> 1..10
...> |> Stream.map(&(&1 * 2))
...> |> IO.inspect()
...> |> Enum.to_list()
#Stream<[enum: 1..10, funs: [#Function<50.38948127/1 in Stream.map/2>]]> # Logged by the `IO.inspect/1`
#Stream<[enum: 1..10, funs: [#Function<50.38948127/1 in Stream.map/2>]]>
```

If you want to inspect the contents of a stream, you have no choice but to realize it -- if you're just debugging, I've oftentimes opted to do the following:

```elixir
iex> 1..10
...> |> Stream.map(&(&1 * 2))
...> |> tap(& &1 |> Stream.take(5) |> Enum.to_list() |> IO.inspect())
...> |> Enum.to_list()
[2, 4, 6, 8, 10] # Logged by the `IO.inspect/1`
[2, 4, 6, 8, 10, 12, 14, 16, 18, 20]
```

Make sure you don't accidentally realize the entire stream when debugging, especially if you're working with potentially infinite streams.

### Accidentally realizing a stream

It can be very easy to accidentally realize a stream when you don't intend to.

Not all `Enum` functions have equivalent `Stream` functions, and whilst your code semantically works the same by calling an `Enum` function in the middle of a `Stream` chain, you're realizing the entire stream at that point which will cause issues if you're working with potentially infinite streams.

Examples of this might include needing to call `Enum.reverse/1`, `Enum.sort/1`, `Enum.sum/1`, or basically anything that requires the entire collection to be processed.

If possible, you're often better trying to refactor your code to realize the stream before you need to call these functions.

Additionally, `Enum.reduce/3` has no one-to-one `Stream` counterpart because it potentially collapses any input into a single value, which is counter to the nature and design of the `Stream` module.

That being said, you can use `Stream.transform/3` to achieve similar results, but it's not as clean as using `Enum.reduce/3`. See the documentation for `Stream.transform/3` and related functions for more information.

For example, the following use of `Stream.transform/3` emulates a lazy `Enum.reduce/3`:

```elixir
iex> 1..10
...> |> Stream.transform(0, fn x, acc ->
...>   new_acc = acc + x
...>   {[new_acc], new_acc}
...> end)
...> |> Enum.to_list()
[1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
```

### Realizing a stream multiple times

One of the cool things about `Stream` is that until you realize it, you've just got a data structure that represents a series of transformations.

This is great (and we'll get to this in a little bit), but it can also be a footgun if you accidentally realize a stream saved to a variable multiple times.

For example, the following code will realize the stream twice:

```elixir
iex> stream = 1..10 |> Stream.map(&(&1 * 2))
iex> Enum.take(stream, 5)
iex> Enum.take(stream, 5)
```

Whilst this seems obvious, streams can be passed around as arguments to functions, and it can be easy to accidentally realize a stream multiple times if you're not careful.

Additionally, because the act of realizing a `Stream` might make API calls, or perform other side-effects, you might end up with unexpected behavior if you realize a stream multiple times.

This is easy to do accidentally, as said above when passing streams around as arguments to functions, because this would be totally fine with an `Enum`:

```elixir
iex> MyApp.Repo.transaction(fn ->
...>   stream =
...>     MyApp.Accounts.Client
...>     |> MyApp.Repo.stream()
...>     |> Stream.chunk_every(1000)
...>     |> Stream.map(&MyApp.Repo.preload(&1, :addresses))
...>
...>   clients = Enum.to_list(stream)
...>   client_count = Enum.count(stream)
...>   addresses_count = stream |> Stream.flat_map(& &1.addresses) |> Enum.count()
...>   {clients, client_count, addresses_count}
...> )
{:ok, [...], 1000, 10000}
```

Whilst this code is semantically fine, and looks okay at first glance, it's actually realizing the stream multiple times (which means doing the database calls and preloading multiple times).

Instead, you might want to refactor to be the following, which will realize the stream once:

```elixir
iex> clients =
...>   MyApp.Repo.transaction(fn ->
...>     stream =
...>       MyApp.Accounts.Client
...>       |> MyApp.Repo.stream()
...>       |> Stream.chunk_every(1000)
...>       |> Stream.map(&MyApp.Repo.preload(&1, :addresses))
...>
...>     Enum.to_list(stream)
...>   )
[...]
iex> client_count = Enum.count(clients)
1000
iex> addresses_count = clients |> Enum.flat_map(& &1.addresses) |> Enum.count()
10000
```

## Stream Composition

One of the most powerful features of `Stream` is that you can compose streams together to build complex data processing pipelines.

A pattern I've started using at [Vetspire](https://vetspire.com/), especially when working on complex report processing, is to build a function that looks something like this:

```elixir
def generate_report(org_id, opts \\ []) do
  {max_concurrency, opts} = Keyword.pop(opts, :max_concurrency, 5)
  {chunk_size, opts} = Keyword.pop(opts, :chunk_size, 1000)

  {progress?, opts} = Keyword.pop(opts, :progress, false)
  {debug_urls?, opts} = Keyword.pop(opts, :debug_urls, false)
  {count?, opts} = Keyword.pop(opts, :count, false)

  MyApp.Repo.transaction(fn ->
    base_query =
      from(x in MyApp.MedicalRecords.Report, where: x.org_id == ^org_id)

    stream =
      base_query
      |> MyApp.Repo.stream()
      |> Stream.chunk_every(chunk_size)

    stream =
      if progress? do
        total_count = MyApp.Repo.aggregate(base_query, :count)

        stream
        |> Stream.with_index(1)
        |> Stream.map(fn {row, index} ->
          IO.puts("Processing row #{min(index * chunk_size, total_count)}/#{total_count}")
          row
        end)
      else
        stream
      end

    stream =
      if debug_urls? do
        Stream.each(stream, & &1 |> to_urls!() |> IO.inspect())
      else
        stream
      end

    stream =
      stream
      |> Stream.map(&MyApp.Repo.preload(&1, [:client, :patient, :doctor]))
      |> Task.async_stream(&generate_rows_for_report/1, max_concurrency: max_concurrency)
      |> Stream.flat_map(fn {:ok, rows} -> rows end)

    if count? do
      Enum.sum(stream)
    else
      file = File.stream!("report.csv")

      stream
      |> CSV.encode!()
      |> Stream.into(file)
      |> Stream.run()
    end
  end)
end
```

Basically, similarly to how you might accumulate a series of transformations against an `Ecto.Query.t()` struct, because an unrealized stream is literally just a composible data structure, you can conditionally apply transformations to the stream based on the options passed in.

This is a pattern I've found to be very powerful as it allows us to define stream resources or pipelines as a sort of "single source of truth" for what data should be processed, and then the actual behavior for realizing that stream can be controlled elsewhere.

At [Vetspire](https://vetspire.com/), we have a lot of small utility functions that take a `Stream` or `Enum` as input, only to do something cool with it, like automatically printing out progress bars, automatically preloading associations efficiently for a `Repo.stream/2`, etc.

## Conclusion

The `Enum` module is the bread-and-butter of working with collections in Elixir, and often times beginners are either unaware of the `Stream` module, or don't understand the benefits of using it.

Hopefully, this post has helped you understand at a high level what `Stream` is, and how it can be used to build complex data processing pipelines in Elixir.

If you're interested in learning more about `Stream`, I recommend checking out the [official documentation](https://hexdocs.pm/elixir/Stream.html) which has a lot of great examples and explanations of how to use `Stream` effectively.

Additionally, I recommend checking out the [Flow](https://hexdocs.pm/flow/Flow.html) library if you're looking to build large-scale concurrent data processing pipelines, as it provides a lot of the same API as `Enum` and `Stream`, but is designed to work with parallel processing in mind.
