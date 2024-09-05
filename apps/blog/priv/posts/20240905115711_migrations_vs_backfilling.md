---
title: Migrations Vs Backfilling
slug: migrations_vs_backfilling
is_draft: false
reading_time_minutes:
published_at: 2024-09-05 11:57:11Z
tags:
  - elixir
  - patterns
---

[Ecto](https://hexdocs.pm/ecto/Ecto.html) migrations are a powerful tool for managing your database schema. They allow you to define changes to your database schema in a way that can be versioned and applied in a consistent manner.

You're likely familiar with the concept of migrations in other languages or frameworks, and Ecto migrations are no different.

However, there's a common pattern that I've seen in Elixir projects that's a big no-no: the use of migrations to backfill data.

## What is Backfilling?

Backfilling is the process of updating existing data in your database to match a new schema or to add new data that wasn't previously present.

When I started at [Vetspire](https://vetspire.com), we had a very normalized database schema. This was great for a lot of reasons, but it made querying data a bit more complex than it needed to be.

A normalized schema is great for ensuring data integrity, but it can be a bit of a pain to work with in practice.

If you're unfamiliar with the concept of normalization, it's a process of organizing your data in a way that minimizes redundancy and dependency. This is great for ensuring that your data is consistent and that you don't have to update it in multiple places.

A normalized schema might look something like this:

```sql
CREATE TABLE organizations (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL
  org_id INTEGER REFERENCES organizations(id)
);

CREATE TABLE posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL
);
```

In order to query all posts for a given organization, you'd have to join the `organizations`, `users`, and `posts` tables together:

```sql
SELECT
  posts.*
FROM
  organizations
JOIN
  users ON users.org_id = organizations.id
JOIN
  posts ON posts.user_id = users.id
WHERE
  organizations.name = 'Vetspire';
```

This is a bit of a contrived example, but you get the idea.

For large reporting workloads, or even just to have something to index on when listing swathes of data, this can be a bit of a pain.

Assume we want to backfill a `organization_id` column on the `posts` table. We could write the following migration to do so:

```elixir
defmodule MyApp.Repo.Migrations.AddOrganizationIdToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add :organization_id, references(:organizations, on_delete: :nothing)
    end

    flush()

    Post
    |> MyApp.Repo.all()
    |> MyApp.Repo.preload(user: :organization)
    |> Enum.map(& %{&1 | organization_id: &1.user.organization.id})
    |> Enum.map(& Map.take(&1, Post.__schema__(:fields)))
    |> then(&MyApp.Repo.insert_all(Post, &1, conflict_target: :id, on_conflict: :replace_all))
  end
end
```

> Note: This code is a bit contrived and doesn't handle all edge cases. It's meant to illustrate the point.

This migration will add an `organization_id` column to the `posts` table and backfill it with the `organization_id` from the associated `user`.

This, however, is a bad idea.

### The Problem(s)

Several problems arise when using migrations to backfill data:

1. **Migrations are meant for schema changes, not data changes.** Migrations are meant to be a way to version your database schema and apply changes in a consistent manner. They're not meant to be used for data manipulation.
2. **Migrations can be slow.** Migrations are usually run in a transaction, which means that they can be slow for large amounts of data. This is problematic if your migrations block deployments and can lead to downtime.
3. **Migrations can be hard to roll back.** If your migration fails halfway through, it can be difficult to roll back the changes. This can lead to inconsistent data.
4. **Migrations can be hard to test.** Testing migrations can be difficult, especially if you're backfilling data. You need to ensure that your migration is idempotent and that it doesn't cause any data integrity issues.

The first issue is admittedly more conceptual than the others, but it's still important to consider.

Another problem with the example migration, not that you couldn't get around it, is that it's referencing the `Post` schema directly. This is a bit of a code smell because `Post` refers to the current version of the schema as it exists in the codebase.

By definition, since migrations are "coupled" to database state relative to other migrations, the schema of the `posts` table may not be the same as the `Post` schema in the codebase.

> You can generally fix this by just refering the raw table (or `Post.__schema__(:source)` if you really don't want to hardcode table names everywhere) in the migration.

## The Solution(s)

Instead of using migrations to backfill data, consider using a separate process to do so.

At places I've worked, I've seen patterns used such as:

1. **Remote Shell** Have developers shell into your deployed application and run scripts to backfill data via CLI.
2. **HTTP API** Expose scripts which can be run via some HTTP or other networking request so you can trigger data migrations to run after deployment.
3. **Supervised Process** A supervised process that runs in the background and backfills data as needed. This can be `start_link`-ed in your application's supervision tree.

None of the above solutions are groundbreaking, but the keen reader might notice that none of them actually solve problems 2 through 4!

What's up with that?

### Essential Complexity

The essential complexity of backfilling data is that you're updating existing data in a way that's not necessarily straightforward.

You likely have a lot of data, or the queries required to complete the backfill are complex.

Running data migrations as part of your migrations exacerbates this complexity because the common conventional understanding is that migrations are expected to complete successfully _in order to have a working application._

This is a bit of a fallacy, but it's a common one.

The issue with this mindset is that this expectation is _not_ true for data migrations. Unless you're comfortable blocking deployments on data migrations, you're going to have to deal with:

- Unknown scales of data, which translates directly to unknown runtimes.
- Unknown complexity of queries, which translates directly to unknown runtimes.
- The application needing to still be running regardless of the state of the data migration.

Additionally, in practice, no one is unit testing their data migrations.

We run our migrations in our CI pipelines and have custom tooling to help catch common footguns, but even if we did have more extensive tests for our migrations... we simply don't have the data scale needed to catch all the edge cases.

Data migrations are just _scripts_. Real pieces of business logic, that should be tested. Having them live in migrations makes them harder to truly test.

These constraints, in my opinion, are real bits of essential complexity inherent to migrations and deployments and life would be much easier if we don't try to couple data migrations with database migrations.

## A Pattern for Backfilling

At [Vetspire](https://vetspire.com), we've adopted a pattern for backfilling data that's worked well for us.

We have a simple [behaviour](https://hexdocs.pm/elixir/Behaviour.html) that we use for all our data migrations, which expects two callbacks to be implemented:

1. `query/0` - This callback should return a list of _things_. Generally, we like returning a list of primary keys, but it doesn't have to be.
2. `update/1` - This callback is given a list of things, and is expected to update them in some way.

We then have a function that:

1. Looks for all modules that implement this behaviour.
2. Checks if they've been completed before (we store completed jobs in the database, much like database migrations).
3. If they haven't, we run them.

As migrations run, we have a process responsible for calling the `query/0` function. If, and only if it returns a non-empty list, we pass that list to the `update/1` function.

The `update/1` function, if well written, updates all records such that `query/0` no longer returns them.

Finally, the process starts over, querying small chunks of data, updating those chunks, and moving on to query the next chunk.

When an empty list is returned by `query/0`, we mark the migration as complete.

This pattern has worked well for us because it:

- Allows us to run data migrations in a way that doesn't block deployments.
- Allows us to write data migrations that forces us to think about how to update data in a way that's idempotent, batched, etc.
- Allows us to test our data migrations in isolation from the rest of the application, because we can simply unit test them.

An example of a data migration that might use this pattern is:

```elixir
defmodule MyApp.DataMigrations.BackfillOrgId do
  @behaviour Monarch

  ...

  @impl Monarch
  def query do
    Post
    |> Ecto.Query.where([p], is_nil(p.organization_id))
    |> Ecto.Query.select([p], p.id)
    |> Ecto.Query.limit(100)
    |> MyApp.Repo.all()
  end

  @impl Monarch
  def update(ids) do
    base_query
    |> Repo.replica().all(timeout: :timer.minutes(20))
    |> Enum.group_by(&[&1.client_id, &1.patient_id])
    |> Enum.flat_map(&build_upsert_rows/1)
    |> Enum.uniq_by(&{&1[:org_id], &1[:client_id], &1[:patient_id]})
    |> Enum.chunk_every(100)
    |> Enum.each(fn chunk ->
      Repo.insert_all("patients_clients", chunk,
        on_conflict: {:replace, [:org_id]},
        conflict_target: [:id]
      )
    end)

    (from x in Post, where: ids in ^ids)
    |> Repo.preload(user: :organization)
    |> Enum.map(& %{&1 | organization_id: &1.user.organization.id})
    |> Enum.map(& Map.take(&1, Post.__schema__(:fields)))
    |> then(&MyApp.Repo.insert_all(Post, &1, conflict_target: :id, on_conflict: :replace_all))

    :batch_complete
  end
end
```

It works by querying 100 posts at a time without an `organization_id`, and then updating them with the `organization_id` from the associated `user`, and recursively calling itself until all posts have been updated.

This pattern is a bit more complex than just writing a migration, but it's also a lot more flexible and allows you to write data migrations that are more robust and easier to test.

You can now unit test this as follows:

```elixir
defmodule MyApp.DataMigrations.BackfillOrgIdTest do
  use ExUnit.Case

  test "query/0" do
    # Setup
    insert(:post, organization_id: nil)
    insert(:post, organization_id: 1)

    assert MyApp.DataMigrations.BackfillOrgId.query() == [1]
  end

  test "update/1" do
    # Setup
    post = insert(:post, organization_id: nil)
    user = insert(:user, organization: insert(:organization))

    MyApp.DataMigrations.BackfillOrgId.update([post.id])

    assert Repo.get!(Post, post.id).organization_id == user.organization.id
  end
end
```

Additionally, nothing is stopping you from running this manually in a remote shell, or via an HTTP API if you wanted to.

## Monarch

At Vetspire, this idea was originally raised by our wonderful [Ivy Markwell](https://medium.com/@ivymarkwell).

As a result we've extracted this pattern into a library called [Monarch](https://hex.pm/packages/monarch).

It's a simple library that provides the behaviour for data migrations, as well as a runner powered by [Oban](https://hex.pm/packages/oban).

The benefits of running our data migrations through Oban are primarily that we can configure:

- How many jobs run concurrently.
- Where they run in our cluster (not all pods run every queue for perf. distribution reasons).
- Schedule jobs to run at specific times of day.
- Temporarily pause for any reasons.
- Retry failed jobs.

As well as leverage [ObanWeb](https://getoban.pro)'s fantastic web dashboard to view and monitor jobs.

Additionally, because we _re-enqueue_ the job after each batch, we can ensure that we're distributing the load across our cluster evenly.

See the [Monarch](https://hexdocs.pm/monarch) documentation for more information.

### Future Work

We're also currently investigate other features that we'd like to add to Monarch, such as:

- **Dry Run Mode** - Run the migration without actually updating any data.
- **Rollback** - Allow migrations to be rolled back.
- **Benchmarking** - Allow migrations to be benchmarked to ensure they're running in a reasonable amount of time.
- **Cycle Detection** - Detect cycles in migrations and alert when they're detected.

It would also be nice to support staged migrations, as well as offering alternative engines and configuration options.

## Conclusion

Migrations are a powerful tool for managing your database schema, but they're not the right tool for backfilling data.

Instead, consider using a separate process to backfill data, and consider using a pattern like the one outlined above to do so.

This pattern allows [Vetspire](https://vetspire.com) to run data migrations over terabytes of data without blocking deployments, and without causing any downtime.

Peace nerds.
