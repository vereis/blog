---
title: The Story of a Function
slug: story-of-a-function
is_draft: true
reading_time_minutes:
published_at: 2024-09-04 16:22:16Z
tags:
  - elixir
  - talk
---

> I gave a talk at [ElixirConf 2024](https://elixirconf.com/2024) about "Building a Framework for Incremental Materialized Views with Ecto".
>
> Unfortunately, the talk didn't go _as smoothly_ as I would have liked, and I ended up glossing over a lot of the details that I wanted to share.
>
> So, I thought I'd edit my speaker notes into some prose that I could share with you all here. I hope you enjoy it!

## Context

Vetspire is a veterinary practice management software that helps veterinarians run their clinics more efficiently.

I joined [Vetspire](https://vetspire.com) in 2021 as their first dedicated fullstack engineer. Prior to this, engineers were paid largely by Vetspire's clients at the time and prioritized features and bugs that were most important to their clients.

Due to this, when I joined, there were a lot of areas of the codebase that I wanted to focus on that had been neglected, and one of the first areas I wanted to focus on was the performance of our application.

This post is about how a small and simple optimization task ended up kicking off a multi-year journey to build a system that would scale with our growing user base.

## The Immunization Panel

One of the core parts of Vetspire is the patient chart, which shows all sorts of information about a patient: their visits, their medical notes, their billing history, etc.

> TODO: add image support

On the right hand side of the patient chart, we have a sidebar which houses a bunch of information that we want to show to our clinicians pretty much at all times. One of the panels we have is the "immunization panel".

The immunization panel shows all of the immunizations that a patient has had, and when they're due for their next immunization. It's a pretty simple panel, but it's one of the most important parts of the patient chart.

We were getting reports that the immunization panel was timing out for some patients, and we needed to fix it. Despite being relatively new, this seemed like a simple enough component to optimize, and would be a good way to get my feet wet with the chart as a whole.

## The Initial Problem

The query that powers the immunization panel was pretty simple. It looked something like this:

```elixir
def list_immunizations(%Patient{} = patient, most_recent? \\ false)

def list_immunizations(%Patient{} = patient, false) do
  Repo.all(from i in Immunization, where: i.patient_id == ^patient.id)
end

def list_immunizations(%Patient{} = patient, true) do
  Repo.all(
    from i in Immunization,
      where: i.patient_id == ^patient.id,
      order_by: [desc: i.inserted_at],
      distinct: i.product_id
  )
end
```

The first clause of the function would return all of the immunizations for a patient, and the second clause would return only the most recent immunization for each product that a patient had received.

Only the second clause was timing out, and we believe it was because we were lacking an index covering `patient_id` and `product_id`. I don't recall the exact details, but we may have been missing an index on `inserted_at` also.

This was an easy fix:

```elixir
create index("immunizations", [:patient_id, :product_id], concurrently: true)
create index("immunizations", [:inserted_at], concurrently: true)
```

> Unfortunately, in hindsight, it would have been nice to know if both of these were strictly needed, but at the time, we were just happy to have fixed the issue.

During our next deployment, we started seeing queries no longer timing out, and people were happy! Done!!

## Unforeseen Consequences

The immunization panel was a simple component, but the query powering it was used in a few other places in three places at the time:

1. The Immunization Panel
2. The Immunization Reminder System
3. The Compliance Dashboard

For now, let's focus on the Immunization Reminder System, because the Compliance Dashboard was completely broken during this time.

The Immunization Reminder System was a feature that would automatically send out reminders to patients when they were due for their next immunization.

It was a simple system that would run once a day, and if a patient was due for an immunization within the next 30 days, it would send out an email to the patient reminding them to book an appointment.

We had an [Oban](https://hexdocs.pm/oban/Oban.html) job that would run once a day, and it would call a function that looked something like this:

```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: %{org_id: org_id}}) do
  %Org{} = org = Entities.get_org(org_id)
  date_from = Timex.shift(Timex.now(), days: 30)

  for immunization <- Clinical.list_immunizations(org, true, date_from) do
    Marketing.send_reminder(patient, immunization)
  end

  :ok
end
```

> This is a simplified version of the code, but it should give you an idea of what we were doing.
>
> In reality, we have to consider whether or not immunizations have been declined, whether or not patients are deceased, etc.

It turns out that our reminder system was broken at the time due to the query timing out, and we accidentally "fixed" it by optimizing the immunization panel query, possibly due to that `inserted_at` index.

However, we started getting two "bug" reports:

1. Some reminders were "duplicated".
2. Clinics wanted to be able to better control the reminders that were being sent out.

The first issue was simple: sometimes a patient would have multiple of the same immunization with different `product_id`s. Maybe they got rabies vaccines from different manufacturers, maybe the patient had a bad reaction to one vaccination and needed to use a different one in the future.

It was completely valid for patients to have immunizations that were the "same" despite being different products entirely.

The second issue was a bit more complex: clinics wanted to be able to control over how reminders were sent out, and we simply didn't have a way to do that at the time.

Importantly, this was an issue that affected the Immunization Panel as well, as the duplicate reminders showed up there too.

## Protocols

The solution that we came up with solving both issues was to:

1. Introduce a new entity called a `Protocol` which would group multiple discrete immunizations/products into a single thing with a `name`, `date`, and `due_date`.
2. Update the query powering the Immunization Panel to use `Protocols` instead of `Immunizations` -- there's a caveat here that I'll go into.
3. Introduce a new entity called a `Cadence` which would have fields like `subject`, `body`, `communication_method`, and `trigger_at`.
4. Update our oban jobs to "zip" together all protocols that were due within a cadence's `trigger_at` condition and send out reminders based on the cadence's configuration.

> NOTE: Protocols here aren't related to [Elixir Protocols](https://elixir-lang.org/getting-started/protocols.html), but instead to the concept of a "protocol" in the medical world.

The Immunization Panel query, now the "Protocols" query, ended up looking something like this:

```elixir
def list_protocols_to_send(org_id, opts \\ []) do
  org_id
  |> base_query()
  |> apply_protocol_filters()
  |> join_immunizations()
  |> apply_custom_filters(opts)
  |> derive()
  |> Repo.all(timeout: :timer.hours(2))
end

defp base_query(org_id) do
  from(p in Protocol,
    as: :protocol,
    where: p.org_id == ^org_id,
    where: p.is_active,
    join: pa in Patient,
    on: true,
    as: :patient,
    join: co in "client_orgs",
    on: co.client_id == pa.client_id and co.org_id == p.org_id
  )
end

defp apply_protocol_filters(query) do
  from([patient: patient, protocol: protocol] in query,
    where: fragment("COALESCE(?, '{}') = '{}'", protocol.species)
      or fragment("lower(?)", patient.species) in protocol.species,
    where: is_nil(protocol.age_low_days)
      or ^now - patient_birthday_fragment(patient) >= protocol.age_low_days,
    where: is_nil(protocol.age_high_days)
      or ^now - patient_birthday_fragment(patient) <= protocol.age_high_days,
    where: not patient.is_deceased
  )
end

defp join_immunizations(query) do
  from([patient: patient, protocol: protocol] in query,
    join: pr in assoc(protocol, :products),
    as: :product,
    left_join: i in Immunization,
    on: i.product_id == pr.id and i.patient_id == patient.id,
    as: :immunization,
    where: is_nil(i.declined) or i.declined == false
  )
end

defp apply_custom_filters(query, []) do
  query
end

defp apply_custom_filters(query, [{:patient_id, patient_id} | opts]) do
  from([patient: patient] in query, where: patient.id == ^patient_id)
  |> apply_custom_filters(opts)
end

defp apply_custom_filters(query, [{:protocol_id, protocol_id} | opts]) do
  from([protocol: protocol] in query, where: protocol.id == ^protocol_id)
  |> apply_custom_filters(opts)
end

defp apply_custom_filters(query, [{:start_due_date, date} | opts]) do
  from([immunization: immunization] in query, where: immunization.due_date >= ^date)
  |> apply_custom_filters(opts)
end

defp apply_custom_filters(query, [{:end_due_date, date} | opts]) do
  from([immunization: immunization] in query, where: immunization.due_date <= ^date)
  |> apply_custom_filters(opts)
end

defp apply_custom_filters(query, [_unknown | opts]) do
  apply_custom_filters(query, opts)
end

defp derive(query) do
  from([patient: patient, protocol: protocol, product: product, immunization: immunization] in query,
    distinct: [patient.id, protocol.id],
    order_by: [
      desc: protocol.id,
      desc: patient.id,
      desc: immunization.date,
      desc: immunization.inserted_at
    ],
    select_merge: %{
      patient_id: patient.id,
      protocol_id: protocol.id,
      org_id: protocol.org_id,
      immunization_id: immunization.id,
      date: immunization.date,
      due_date: immunization.due_date
    }
  )
end
```

This was quite the refactor, but we didn't think it was too bad at the time. In case the query above is a bit hard to follow, here's a rough breakdown of what it's doing:

1. We start with a base query that gets all protocols for an organization.
2. We join all patients which are eligible for that protocol.
3. For those patients, we join all their immunizations that could fulfill that protocol.
4. We apply any custom filters that were passed in as options, such as a due date range filter.
5. We then derive the query result, a list of maps with a `protocol_id`, `patient_id`, and `due_date` by taking query results and keeping only the most recent rows for each `{protocol_id, patient_id}` pair.

As large as the query is, it isn't doing anything _too_ complicated once you're used to working with more complex queries. It's just a bit daunting but arguably there's essential complexity here!

Our Immunization Panel was now our Protocols Panel, and it was working great! We were able to show all of the protocols that a patient was due for, sans duplication!

For our reminders, we were able to rewrite our job as follows:

```elixir
@impl Oban.Worker
def perform(%Oban.Job{args: %{org_id: org_id}}) do
  %Org{} = org = Entities.get_org(org_id)

  for cadence <- Marketing.list_cadences(org, active: true),
      date_from = Timex.shift(Timex.now(), days: cadence.trigger_at),
      protocol <- Clinical.list_protocols_to_send(org, [start_due_date: date_from]) do
    Marketing.send_reminder(patient, protocol)
  end

  :ok
end

def perform(%Oban.Job{}) do
  for org <- Entities.list_orgs() do
    %{}
    |> new(%{org_id: org.id})
    |> Oban.insert!()
  end

  :ok
end
```

> Note: I'm going to omit details about adding indexes. We're now at a point where we're adding indexes as needed, and if we miss any we end up fixing them later so glossing over indexes is fine.

Now, our reminder system was working pretty well too! We were able to send out reminders based on protocols that were due within a certain time frame, and we were able to control which reminders were sent out and when.

Even better, now our reminders were sent batched by cadence, so we were able to minimize the amount of data any one query had to process.

Do note that we had a nasty `timeout: :timer.hours(2)` in our `list_protocols_to_send` function. This was a sign of things to come...

## Growing Complexity

As Vetspire grew, so did the complexity of our system. We started getting requests to send out reminders based on things that weren't immunizations.

For example, we had a table called `order_items` which was a record of a patient purchasing a product -- any product. It could be anything from a bag of dog food to a flea collar to actual medication.

Unlike an immunization, an order item didn't have a `next_due_date` field, but we were able to derive one based on the product's `duration_days` field.

We ended up adding some logic that could "derive" a product's `next_due_date` if it didn't actually have one set, and we simply added another join to our query to factor in order items as well...

```elixir
def list_protocols_to_send(org_id, opts \\ []) do
  org_id
  |> base_query()
  |> apply_protocol_filters()
  |> join_immunizations()
  |> join_order_items()
  |> apply_custom_filters(opts)
  |> derive()
  |> Repo.all(timeout: :timer.hours(4))
end

defp join_order_items(query) do
  from([patient: patient, protocol: protocol, product: product] in query,
    left_join: o in OrderItem,
    on: o.patient_id == patient.id and o.product_id == product.id,
    as: :order_item,
    where: is_nil(o.declined) or o.declined == false,
  )
end

defp derive(query) do
  from([patient: patient, protocol: protocol, product: product, immunization: immunization, order_item: order_item] in query,
    distinct: [patient.id, protocol.id],
    order_by: [
      desc: protocol.id,
      desc: patient.id,
      desc: (is_nil(immunization.id) and is_nil(order_item.id) and true) or false,
      desc: coalesce(immunization.date, order_item.date),
      desc: coalesce(immunization.inserted_at, order_item.inserted_at)
    ],
    select_merge: %{
      patient_id: patient.id,
      protocol_id: protocol.id,
      org_id: protocol.org_id,
      immunization_id: immunization.id,
      order_item_id:
        fragment(
          "CASE WHEN (? IS NOT NULL) THEN ? ELSE ? END",
          immunization.id,
          immunization.order_item_id,
          order_item.id
        ),
      date:
        coalesce(immunization.date,
          coalesce(order_item.date, type(protocol.inserted_at, :date))
        ),
      due_date:
        coalesce(immunization.due_date,
          coalesce(order_item.date, type(protocol.inserted_at, :date))
          |> date_add(protocol.duration_days, "day")
        )
    }
  )
end
```

> Note: I'm not showing any unchanged code for brevity.

This was a simple enough change, but it was a sign of things to come... but before that, let's quickly explain the change:

- Instead of only joining immunizations, we now join order items as well.
- We now need to compare the `date` and `inserted_at` fields of immunizations and order items to determine which one is more recent.
- If an order item is what ends up deriving a protocol, we need to additionally derive a `due_date` based on its product's `duration_days` field.

So except for the join condition, the query basically only needed updates to the `order_by` clause and the `select_merge` clause.

> Note: `Ecto.Query.API.coalesce/2` is a helper function that returns the first non-null value in a list of values. This proved super handy.
>
> There are cases, however, where we end up writing a `CASE WHEN .. THEN .. ELSE .. END` clause to handle more complex logic.
> This is a hack that allows us to do some boolean logic similar to: `order_item_id = immunization.id && immunization.order_id || order_item.id`.

Suprisingly, this change pretty much just worked and again, had the benefit of applying to both the Protocols Panel and the Reminder System.

Do note, however, our `timeout: :timer.hours(2)` had now become `timeout: :timer.hours(4)`.

## A Pattern Emerges

One of the things I believe is the idea that any patterns being used and followed in a codebase likely only exists because they are some local minimum implementation needed to solve a problem at the time due to the incremental nature of software development.

In our case, we had a pattern that was emerging, and it was working, so we stuck to it. We didn't give it too much more thought.

This pattern was useful because when the request came in to add support for "clinical overrides" to the reminder system, we were able to quickly implement it.

Basically, clinician's wanted the ability to override the due date of a protocol reminder. Moreover, they also wanted to be able to create custom protocol reminders out of thin air.

Clinicians currently did this by manually changing billing or medical records so as to trigger the due date they wanted, even after the fact, which was a big no-no. So we took on the feature request!

Our query works by deriving a list of protocol reminders from what is currently two distinct inputs, sorting them, and taking the most recent action that fulfills a protocol for a patient...

So it was easy to create a new `CustomPatientProtocol` entity which had a `patient_id`, a `protocol_id`, `inserted_at`, and a `due_date`, build a UI for it, and just consider it another input to our query.

```elixir
def list_protocols_to_send(org_id, opts \\ []) do
  org_id
  |> base_query()
  |> apply_protocol_filters()
  |> join_immunizations()
  |> join_order_items()
  |> join_custom_patient_protocols()
  |> apply_custom_filters(opts)
  |> derive()
  |> Repo.all(timeout: :timer.hours(8))
end

defp join_custom_patient_protocols(query) do
  from([patient: patient, protocol: protocol] in query,
    left_join: c in CustomPatientProtocol,
    on: c.patient_id == patient.id and c.protocol_id == protocol.id,
    as: :custom_patient_protocol
  )
end

defp derive(query) do
  from([patient: patient, protocol: protocol, product: product, immunization: immunization, order_item: order_item, custom_patient_protocol: custom_patient_protocol] in query,
    distinct: [patient.id, protocol.id],
    order_by: [
      desc: protocol.id,
      desc: patient.id,
      desc: (is_nil(immunization.id) and is_nil(order_item.id) and is_nil(custom_patient_protocol.id) and true) or false,
      desc: coalesce(immunization.date, order_item.date, custom_patient_protocol.date),
      desc: coalesce(immunization.inserted_at, order_item.inserted_at, custom_patient_protocol.inserted_at)
    ],
    select_merge: %{
      patient_id: patient.id,
      protocol_id: protocol.id,
      org_id: protocol.org_id,
      immunization_id: immunization.id,
      order_item_id:
        fragment(
          "CASE WHEN (? IS NOT NULL) THEN ? ELSE ? END",
          immunization.id,
          immunization.order_item_id,
          fragment("CASE WHEN (? IS NOT NULL) THEN ? ELSE ? END", order_item.id, order_item.id, custom_patient_protocol.id)
        ),
      date:
        coalesce(immunization.date,
          coalesce(order_item.date,
            coalesce(custom_patient_protocol.date, type(protocol.inserted_at, :date))
          )
        ),
      due_date:
        coalesce(immunization.due_date,
          coalesce(order_item.date,
            coalesce(custom_patient_protocol.date, type(protocol.inserted_at, :date))
          )
          |> date_add(protocol.duration_days, "day")
        )
    }
  )
end
```

And unsurprisingly, this worked too! We were able to quickly implement the feature, and it was working great!

The only issues were:

1. Our query was getting slower and slower.
2. The query, if it wasn't unwieldy already, was only getting worse and worse.

Additionally, we were seeing the runtime of our query increasing steadily over time as our user base grew, and while the Protocols Panel was completely fine (due to being scoped to a single patient), the Reminder System was starting to take longer and longer to run.

When we were profiling, we noticed the bulk of the time Postgres was trying to handle all the `LEFT_JOIN`s we were doing and we were paging out to disk constantly which tanked performance.

Our query had to consider every permutation of immunizations, order items, and custom patient protocols for every patient at a practice and this just wasn't going to scale.

So, we had to take a step back and think about how we could optimize this query, and that's when we started thinking about materialized views.

## ELI5: Materialized Views

A [View](https://www.postgresql.org/docs/13/tutorial-views.html) in a database is a virtual table that is based on the result of a query.

It's a way to save a query so you can reference it later.

Views act like tables, but they don't store any data themselves. Instead, they store the query that generates the data. When you query a view, the database runs the query and returns the results.

Imagine Vetspire has a table called `orders` with an `invoiced: boolean()` field. We could create a view called `invoices` that only shows orders that have been invoiced.

```sql
CREATE VIEW invoices AS SELECT * FROM orders WHERE invoiced = true;
```

Which you could then query like so:

```sql
SELECT * FROM invoices;
```

> Note: This is super cool because you can use views in lieu of tables for `Ecto.Schema`s too!

However, a view alone doesn't help us with our problem as every query to a view still executes the underlying view's base query.

A [Materialized View](https://www.postgresql.org/docs/13/tutorial-materialized-views.html) is a view that _stores_ the results of the query in a table.

You can think of a materialized view as a snapshot of a query's results at a specific point in time. A cache.

So what if we could create a materialized view that stored the results of our `list_protocols_to_send/2` query? Then, instead of deriving every protocol reminder (and thus run all our expensive joins and sorting and deriving) on demand, we could directly query the materialized view instead.

Materialized views act like tables too, so they could be indexed for optimal lookup performance.

The issue we have is three-fold however:

1. You have to manually refresh a materialized view to update its data. Postgres does not handle this for you.
2. Refreshing a materialized view is an expensive operation, as it re-runs the query and rewrites the table. Our query was already starting to get unnerveingly slow and we'd eventually get to the point where it took longer than 24 hours to run.
3. While the reminder system only ran once a day, and thus could deal with stale data, the Protocols Panel needed to be real-time.

So, we had to look into something called an "Incremental Materialized View".

### Incremental Materialized Views

An "Incremental Materialized View" is a materialized view that only updates the rows that have changed since the last refresh.

This is a bit more complex than a regular materialized view, but it's a lot more efficient, because instead of re-running the entire query and rewriting the entire table, you only have to update the rows that have changed.

At the time of writing, Postgres doesn't support incremental materialized views out of the box, but there are products and projects that you can use to do so:

- [Materialize](https://materialize.com/)
- [TimescaleDB](https://www.timescale.com/)
- [pg_ivm](https://github.com/sraoss/pg_ivm)
- Probably more!

However, we didn't want to introduce a new dependency to our stack, so we did what lots of people do: we emulate them!

### Database Triggers

A [Database Trigger](https://www.postgresql.org/docs/13/plpgsql-trigger.html) is a function that is automatically executed when a certain event occurs in a database.

For example, you could create a trigger that automatically updates a materialized view whenever a row in a table is inserted, updated, or deleted.

In fact, this is exactly what we did!

We created a trigger that would automatically update our materialized view whenever a row in the `immunizations`, `order_items`, or `custom_patient_protocols` table was inserted, updated, or deleted.

This way, we were able to keep our materialized view up-to-date without having to refresh the entire table every time.

This worked... poorly in practice, though initial implementation was promising.

We added some Ecto migrations to create triggers that looked like this, for all protocols inputs:

```sql
CREATE OR REPLACE FUNCTION pp_refresh_order_items()
  RETURNS trigger AS
$BODY$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    INSERT INTO patients_protocols(patient_id, protocol_id, order_item_id, is_preemptive, org_id, date, due_date)
      #{select_active_patient_protocols(["patients.id = NEW.patient_id"])}
    ON CONFLICT (patient_id, protocol_id) DO UPDATE SET
      #{on_conflict_update_fields()}
    RETURN NULL;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM patients_protocols WHERE patient_id = OLD.patient_id;
    INSERT INTO patients_protocols(patient_id, protocol_id, order_item_id, is_preemptive, org_id, date, due_date)
      #{select_active_patient_protocols(["patients.id = OLD.patient_id"])}
    ON CONFLICT (patient_id, protocol_id) DO UPDATE SET
      #{on_conflict_update_fields()}
    RETURN NULL;
  END IF;
END;
$BODY$
  LANGUAGE plpgsql;
```

This basically says: if a row is created or updated in `order_items`, upsert a row in our materialized view: `patients_protocols`, with whatever fields are needed.

The issue is if an `order_item` is deleted, we have to delete all rows in our materialized view that are associated with that `order_item`, and effectively refresh large swathes of `patients_protocols` to make sure any previous input re-triggers the correct output as needed.

> What I mean by this is, if a protocol "Rabies" was derived by an immunization first, then replaced by an order item, if that order item is deleted... we have to re-derive the protocol from the immunization.
>
> This is a bit of a simplification, but it should give you an idea of the complexity we were dealing with.

Our query was updated to look like this:

```elixir
def list_protocols_to_send(org_id, opts \\ []) do
  opts
  |> Enum.reduce(from(x in "patients_protocols", where: x.org_id == ^org_id), fn
    {:patient_id, patient_id} -> where x.patient_id == ^patient_id
    {:protocol_id, protocol_id} -> where x.protocol_id == ^protocol_id
    {:start_due_date, date} -> where x.due_date >= ^date
    {:end_due_date, date} -> where x.due_date <= ^date
    _ -> x
  end)
  |> Repo.all(timeout: :timer.minutes(5))
end
```

This was a big change, but it was working! Our query was now running in a fraction of the time it used to, and we were able to scale our system to handle more users.

## Surface Tension

This worked, until it didn't!

We ran into the following issues with this approach:

- We had to be very careful about how we wrote our triggers, as they could easily time out.
- We had to make sure every input to our materialized view was covered by a trigger, and that every trigger was written correctly. If we didn't cover some case, we'd end up with stale or incorrect data.
- Other engineers unfamiliar with the system had a hard time understanding how it worked. Triggers are to application logic what "spooky action at a distance" was to General Relativity.

However, querying was super duper fast!! We were able to query our materialized view directly and get the data we needed in a fraction of the time it used to take.

This system did cause a few incidents however. We ended up learning that triggers have different blast radii, and that we had to be very careful about how we wrote them.

For example, if a patient is given an immunization, the blast radius of that trigger is small, and we can reason about it pretty well. We only have to upsert a single row in our materialized view.

However, if someone disables and then re-enables a protocol, the blast radius of that trigger is much larger, and we have to re-derive all the protocols for that all potential fulfilling patients, factoring in the totality of all inputs. No matter what this is going to time out...

So, while this was a decent solution with respect to runtime cost, it just was not something that we felt confident in maintaining in the long term.

Instead, we went back to our profiling...

## A Red Letter Day

The problem was that doing our `LEFT JOIN`s was slow. We realized our materialized view solution just slightly missed the _point_ of what our problems were.

We realized that instead of opening ourselves up to large blast radius triggers (deriving the final protocol structs we wanted), we could instead have several smaller materialized views that stored the most recent order item, immunization, and custom patient protocol per patient, per product ID, and per protocol ID respectively.

This way, we knew the blast radius of all our triggers was small and understandable. Deleting an order item would only affect the materialized view for that order item, and not the entire `patients_protocols` table.

These "most_recent" materialized views could then be joined together to get the data we needed, and protocols could be derived from these smaller materialized views much, much faster than doing the `LEFT JOIN`s on the fly.

This was a big change, but it was well worth the performance tradeoff. We decided to rewrite our system again, and this time, we were targeting the following goals:

1. Ability to scale with our growing user base.
2. Get rid of "spooky action at a distance" -- we wanted all the actual code to be in Elixir so anyone could see what was going on.
3. Have materialized views that we could query directly whenever we needed, while being as low blast radius as possible.
4. Ideally having a single code path for anything that needed to query protocols. We didn't want to fork the protocols panel and the reminder system.
5. Have minimal impact on database memory.

> Note: We could have forked the protocols panel and the reminder system, but we wanted to keep things DRY and have a single source of truth for what protocols were due for a patient.
>
> We did experiment with forking the protocols panel and the reminder system, but it was a nightmare to maintain as feature requests or logic changes were being made, as we had to make sure they were reflected in both places.
>
> This was not trivial when working with materialized views and triggers on one hand, versus a regular Ecto query on the other.

## Cinema

We ended up building a new framework called `Cinema`, which introduced two basic concepts:

1. A `Projection`, which is a recipe for how to derive and populate rows in a materialized view from other data sources, such as your other database tables or even other projections.
2. A `Lens`, which is a way to "focus" on a specific part of the data that you're interested in, and is automatically applied to your projections. Basically, if you have a lens that has a `patient_id: 123` filter, all projections that need to be run will have their derivation functions automatically scoped to that single patient. No more full table materialized view refreshes!

### Projections

A `Projection` was just a behaviour defining three callbacks: `derivation/2`, `inputs/0`, and `outputs/0`.

The `inputs/0` callback would return a list of other projections that this projection depended on, and the `outputs/0` callback would return data in the form of an Ecto query, or enumerable which was passed into other projection's `derivation/2` callbacks.

The `derivation/2` callback would take the data from the `outputs/0` callback, stream over it, and should make several calls to `Cinema.Projection.materialize/2` to automatically upsert rows in the materialized view.

Additionally, derivations could opt into manually dematerializing rows by calling `Cinema.Projection.dematerialize/2` which is useful for materializing changes to views that can't be upserted (i.e. handling deletes).

### Lenses

Lenses are automatically applied to all outputs plugged into a derivation. This was, your projections can be run for a single patient, single location, or across an entire organization.

This way, we could have a single source of truth for _how_ a protocol was derived, but we only needed to rematerialize and consider dependencies for the particular lens you're trying to query.

### Our Pipeline

Recall that we have the following inputs to consider to derive a protocol:

1. Immunizations
2. Order Items
3. Custom Patient Protocols

We ended up creating three projections: `MostRecentImmunizations`, `MostRecentOrderItems`, and `MostRecentCustomPatientProtocols` which would store the most recent immunization, order item, and custom patient protocol per patient, per product ID, and per protocol ID respectively.

We then ensured that any lenses we'd ever need to use had their filters covered by indexes on these materialized views. This way, we could query these materialized views directly whenever we needed to, and we could be confident that the query would be fast.

Once these materialized views were in place, we then had another projection called `ProductProtocols` took these as inputs.

The `ProductProtocols` projection was then responsible for deriving itself multiple times, once per input. Each derivation would then upsert rows into the `product_protocols` materialized view if and only if rows resulting from a given input were more recent than the current row in the materialized view.

This way we didn't have to write any of the old, complex grouping/ordering logic as everything was just a coalesced datetime comparison.

Querying `product_protocols` was then all we needed to do to render the protocols panel.

On top of this, we had further projections to scale down the amount of data needed to be considered by the reminder system called `OutstandingProtocols` and `TriggeredCadences`.

The `OutstandingProtocols` projection would take the `product_protocols` materialized view as an input, and would filter out any protocols that were considered "outstanding" for a cadence in the system. A lot of protocols might exist but the reminders system only needed to consider a subset of them after all, and the less data you need to query the better.

The `TriggeredCadences` projection would then take the `OutstandingProtocols` materialized view as an input, and would group all outstanding protocols by cadence, and then materialize rows with an idempotency key. If a row was materialized, we'd enqueue a job to send out a reminder via SMS or email as a side-effect. This way, we could ensure that we didn't send out duplicate reminders.

I can't show you the code for our projections, but they look something like this:

```elixir
defmodule Cinema.Movies.MostRecentShowings do
  use Cinema.Projection,
    read_repo: Cinema.Repo.Replica,
    write_repo: Cinema.Repo,
    on_conflict: [:replace_all],
    conflict_target: [:movie_id, :date]

  schema "most_recent_showings" do
    field :movie_id, :id
    field :date, :utc_datetime
    field :viewer_count, :integer
  end

  @impl Cinema.Projection
  def inputs, do: [Cinema.Movies.Movie]

  @impl Cinema.Projection
  def output, do: from x in __MODULE__

  @impl Cinema.Projection
  def derivation({Cinema.Movies.Movie, stream}, lens) do
    Cinema.Projection.dematerialize!()

    stream
    |> Stream.chunk_every(200)
    |> Stream.map(&base_query(&1, lens))
    |> Stream.each(&Cinema.Projection.materialize!/1)
    |> Stream.run()
  end

  defp base_query(movie_ids, lens) do
    from m in Cinema.Movies.Movie,
      where: ^lens.filters,
      where: m.id in ^movie_ids,
      join: a in assoc(m, :showings),
      group_by: [m.id, m.date]
      select: %{
        movie_id: m.id,
        date: m.date,
        viewer_count: count(a.id)
      }
  end
end
```

When run, this projection would stream over 200 movies at a time scoped to your lens (say we have multiple cinemas in many countries), for that batch, we'd select a row per movie and date with the number of showings that day, and we materialize that row into the `most_recent_showings` materialized view upserting as needed.

### Engines

Note that our pipeline as described above is a graph of projections. This means a few things:

- We have to run projections in a specific order, as some projections depend on the output of other projections.
- We can determine if projections can be executed in parallel
- How a given projection is executed is an implementation detail so long as the inputs and outputs are respected.

We ended up creating an `Engine` behaviour that defined a single function: `run/2`. This function would take a projection and a lens, and would run the projection with the lens applied.

We then had two implementations of this behaviour: `Cinema.Engine.Task` and `Cinema.Engine.Oban.Pro.Workflow`.

The `Cinema.Engine.Task` engine would:

- Run projections via the standard Elixir `Task` module
- Could be awaited for sycnhronously feeling execution
- Still leveraged parallelism where possible

The `Cinema.Engine.Oban.Pro.Workflow` engine would:

- Run projections via [ObanPro Workflows](https://hexdocs.pm/oban_pro/Oban.Pro.Workflow.html)
- Leveraged parallelism where possible
- Would distribute load across our cluster
- Give us the ability to schedule jobs (and thus when reminders go out)
- Give us resiliency guarantees and error handling callbacks
- Give us the ability to tune performance via [ObanWeb](https://hexdocs.pm/oban_web/ObanWeb.html)

When querying the Protocols Panel, we'd run:
```elixir
iex> Cinema.project(ProductProtocols, [patient_id: 123], engine: Cinema.Engine.Task)
{:ok, [%ProductProtocol{...}, ...]}
```

When running the reminder system, we'd run:
```elixir
iex> Cinema.project(TriggeredCadences, [org_id: 123], engine: Cinema.Engine.Oban.Pro.Workflow, async: true)
{:ok, %Cinema.Projection{async?: true}}
```

> Aside: the `async: true` option tells `Cinema` not to await the result of a given projection.

Both engines supported materialiazing projections in parallel if possible, and because our dependency graphs looked like:

```elixir
[
  TriggeredCadences,
  OutstandingProtocols,
  ProductProtocols,
  [
    MostRecentImmunizations,
    MostRecentOrderItems,
    MostRecentCustomPatientProtocols
  ],
  Patients
]
```

We got some performance gains by projecting the most recent materialized views in parallel.

### The Result

This was a big change, but it was well worth the performance tradeoff. We were able to query our materialized views directly whenever we needed to, and we could be confident that the query would be fast enough for the context a request was made in.

We were able to scale our system to handle more users, and we were able to get rid of "spooky action at a distance" by having all the actual code in Elixir so anyone could see what was going on.

We're starting to roll `Cinema` out as a solution for caching intermediate results for a bunch of reporting and analytics purposes as well, and as a result we've been decoupling the system from Vetspire's main repo.

Because of this, we've decided to open source `Cinema` as a standalone library, and we're excited to see what other people can do with it!

You can get [Cinema here!](https://hex.pm/packages/cinema).

## Deliverance

Recall that at the beginning of this post I stated that we had three different features that used the same query to derive protocols:

1. The Protocols Panel
2. The Reminder System
3. The Compliance Dashboard

The Protocols Panel needed to be real-time, but was scoped to a single patient at a time.

The Reminder System needed to be run once a day, and was scoped to a single clinic at a time.

However, the Compliance Dashboard was scoped to an entire organization at a time. We haven't spoken about this yet!

The Compliance Dashboard was a feature that allowed an organization to see how well they were doing at following protocols. It would show them how many protocols were due, how many were overdue, and how many were completed. It additionally allows users to list and search every protocol triggered for all patients at that org.

This was... always broken prior to our `Cinema` rewrite, and in fact, even with all of the initial trigger based work we did, the compliance dashboard was never updated to read from protocols directly -- it always went through `"immunizations"`.

A few years passed since the beginning of this story (and the compliance dashboard had been neglected since before I joined), and we ended up wanting to prioritize it on our roadmap again.

The interesting thing here is that using `Cinema` and materialized views as an implementation for the underlying protocols engine led to an interesting side effect...

Unlike the protocols panel and the reminder system which both needed to rematerialize the materialized views that powered them, the compliance dashboard _simply needed to list_ the contents of the `ProductProtocols` view.

This was because it could rely on the fact that:

- Once a day, all locations have their protocols derived and materialized.
- In real time, individual patient's protocols may be derived and materialized as needed.

The compliance dashboard was a feature that was totally ok with this "eventual consistency", so all it needed to do was to query the `ProductProtocols` materialized view directly.

Because of this, we were able to quickly implement the compliance dashboard, and it was working great!

## Conclusion

We've come a long way from a naive query with complex joins that was slow, to a system that used materialized views and triggers to keep the data up-to-date, to a system that used smaller materialized views and a new framework called `Cinema` to query the data directly.

We've learned a lot along the way, and we're excited to see what other people can do with `Cinema`!

Happy hacking!
