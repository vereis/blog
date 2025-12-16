---
title: You have built an Erlang
slug: you-built-an-erlang
is_draft: false
reading_time_minutes:
published_at: 2024-11-26 14:19:59Z
description: |
  You wanted a simple service notification system, so you added HTTP callbacks, then queues, then retries, then supervision...

  Congratulations! You've built an ad-hoc, informally-specified, bug-ridden slow implementation of half of Erlang.

  A satirical journey through accidentally reimplementing the actor model as seen on Hacker News.
tags:
  - elixir
  - erlang
---

> This post will make more sense if you first read [Dear Sir, You Have Built a Kubernetes](https://www.macchaffee.com/blog/2024/you-have-built-a-kubernetes/).

## Dear Friend...

I regret to inform you that -- despite your best intentions -- **you have built an Erlang**.

I know that you never meant for this to happen, but happen... it did.

### The Innocent Beginning

You just needed a `simple` way to notify services when data changed.

> No big deal, right?

- A full-blown message bus? Eugh, **overkill**.
- A background job? **YAGNI**, the koans scoffed...

So you started small:

```python
def notify_service(event, payload):
  requests.post(f"{service.url}/events", json=payload)
```

> "HTTP is simple!" you declared. "What could go so wrong?"

### The Spaghetti Creeps In

But then, you started getting customers. Your startup thrived.

Suddenly, **everything** needed to know **everything** else:

- Who just signed up?.. Flows for mail providers... custom domains...
- What action was performed?.. When, what, and how?
- Did the user close the modal?.. Did they cancel? Maybe refreshed?

Your codebase became a tangle of ad-hoc HTTP calls, each one a little more complex than the last.

Like an invasive species, these calls spread through your business logic, impossible to remove without ripping out half the ecosystem.

### A Tale of Subscriptions

> "There... there just had to be a better way..." you thought.

Then it hit you: **subscriptions.**

Each service could subscribe to events it cared about, and you could publish events to all subscribers.

Complexity... tight coupling... adieu! You throw something together:

```python
def notify_service(event, payload):
  subscribers = db.query("SELECT url FROM services WHERE event = ?", [event])
  for sub in subscribers:
      do_notify_service(sub.url, payload)
```

**"Elegant!"** you cried!

You built a lightweight system to send notifications as needed. Surely, this would be enough.

But as traffic grew and business boomed, your support team heard whispers of **invalid states**.

A user created an account, but one of your `POST` requests timed out.

> Subsequent services were confused. They thought the user was already registered, but your database said otherwise.
>
> Migrating back to a good state took hours and hours... no telemetry, no logs, no clue...

### Retry, Retry, Retry

You were horrified. You had to fix this.

"No problem going forward," you thought. "We can just retry!"

> You didn't want `Kafka`, even `SQS` was too much... you wanted simplicity... you knew what you were doing.

```python
def notify_service(event, payload):
  queue.insert(event, payload, retries=3)
```

It wasn't pretty... your database cried... but **it was yours** and **it worked**...

Time to move on.

### The Descent into Madness

Your system... homegrown. Your profits... rised.

Your startup just landed a big contract. You were scaling up, and your system was chugging along.

**Everything** went down. **Everyone** complained.

> The database is down. The queues are full. The services are deadlocked.
>
> Dear friend, you **need** to fix this or we're all out of a job.

Services just poll from our queue? How did this even pass code review?

Hmm.. `git blame`... *"Oh, that was me."*... the shame.

- Our pods scale dynamically.
- Too many exhausts our database connections and adds too much load...
- Our queues are full of retries.
- Our services are deadlocked.

This would have been better with good old `HTTP`... let's step back...

> What if we just... **"No, no, no!"** you thought. **"We can fix this."**

We can look up pods via `k8s` and `DNS`... we can write receipts to the database, but `POST` first we shall...

We can encode Pod IDs, targets, channels in our payload... we can use `gRPC`... each pod **is its own queue**... a mailbox...

```python
{
  "event": "user_signup",
  "payload": {...},
  "target_pod": "web-xyz123"
}
```

On boot just check for missed messages and try anew...

```python
def check_for_missed_messages():
  missed = db.query("SELECT * FROM messages WHERE pod_id = ?", [pod_id])
  for message in missed:
      do_notify_service(message.target_pod, message.payload)
```

Just write back acknowledgements, and everything will be fine...

```python
def handle_event(event):
  process_message(event)
  db.execute("UPDATE messages SET status = 'ack' WHERE id = ?", [event.id])
```

### The Precipice of Fragility

But distributed systems are fragile.

- Processes died sporadically.
- Double-acknowledging events.
- Pods fought over missed events.

Chaos ensued.

> Pods seem healthy, but they're not processing messages...
>
> "I've read about this in a book!", you thought. This is a `netsplit`...!

Like a true engineer, a 10x-er, a ninja wearing many hats, you dove in:

1. Let's implement some `timeouts`.
2. Some `heartbeats` to better track our pods.
3. Each pod should be a state machine.
4. `SELECT FOR UPDATE` to prevent deadlocks.

```python
class Worker:
    def __init__(self):
        self.state = "idle"
        self.current_event = None
        self.retries = 0
```

You even added telemetry, introspection, and logging.

**This is good engineering!** you thought. **This solves real problems!**

> Dear friend, let's open source this! Let's make it a library!
>
> The whole world needs this!

And then, you took a vacation.

### The Bitter End

Naturally, something went wrong...

- Cascading timeouts...
- Deadlocked tables...
- Your team, egyptologists, working to decipher your hieroglyphics...

You get paged at 3 AM. You're in Honolulu, sipping a Mai Tai...

**"This needs documentation!"** you declared.

> **"How do I even explain this to the team?"** you thought.
>
> It's so simple... its just queues, and retries, and service discovery... and heartbeats...
>
> It's just state machines... it's just mailboxes... how did this go so, so wrong?

You began to write... you began to train... you began to refactor...

- Document the workflows.
- Tighten the APIs.
- Make all your stateful workers atomic.
- Interfaces, strategies, patterns galore.

> "This is so beautiful!" you thought. "This is so clean!.. its finally right..."

### Awakening

But now, here you stand...

You’ve built:

- An asynchronous, dynamic food-web of services.
- Supvervision trees, albeit by another name.
- Stateful, isolated processes, in some limited, ad-hoc way.
- Synchronous, and asynchronous requests, to fulfill all possible needs.
- Telemetry, introspection, and logging, to track all the things.
- Distributed message queues (that still aren't quite sharded right).

> **Dear friend,** driven by a desire for simplicity, refusal to use tools deemed `esoteric` or `complex`, you've been brought full circle.
>
> **Dear friend,** I regret to say... **you have built an Erlang.**

**Addressed to:**

Those who wanted to `POST` events between a few services.

## Addendum

This post is admittedly quite a bit of a joke.

When I read the origin [Dear Sir, You Have Built a Kubernetes](https://www.macchaffee.com/blog/2024/you-have-built-a-kubernetes/) post, I couldn't help but think of the many times I've seen this pattern in the wild.

Frankly, I feel like `Kubernetes` is itself a bit of an Erlang in many senses.

The whole thing reminds me of `Virding's Law`:

> Any sufficiently complicated concurrent program in another language contains an ad hoc informally-specified bug-ridden slow implementation of half of Erlang.

I do want to note, however, that I don't think this is a bad thing.

At the end of the day, we all have to make trade-offs.

Maybe sure, you don't want to pull `Erlang` into your stack, maybe you don't want to use `Kafka`, or `RabbitMQ`, or `Redis`, or whatever.

That's totally okay.

But I do think it's important to recognize that there are trade-offs to be made.

Sometimes, even if you start out with a simple solution, there are opporunities along the way where you can just stop the train and say "Hey! Maybe we should just `X` for this instead!"

> **Edit:** I'm actually very surprised this hit the front page of [Hacker News](https://news.ycombinator.com/).
>
> I threw this together very quickly. I didn't even think it would be a good post.
>
> As a result of some feedback, I've added some formatting and fixed a few clunky bits, but alas.
>
> If you want to see the original version, you can find it in this file's `git` history!
