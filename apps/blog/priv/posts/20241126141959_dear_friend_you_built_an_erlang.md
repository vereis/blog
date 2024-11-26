---
title: You have built an Erlang
slug: you_built_an_erlang
is_draft: false
reading_time_minutes:
published_at: 2024-11-26 14:19:59Z
tags:
  - erlang
  - humor
---

> This post will make more sense if you first read [Dear Sir, You Have Built a Compiler](https://www.macchaffee.com/blog/2024/you-have-built-a-kubernetes/).

Dear friend,

I regret to inform you that, despite your best intentions, you have built an Erlang.

I know all you wanted was to "keep it simple." You just needed a way to notify your services when data changed—nothing fancy. A dedicated background job system or message bus? Too much. "YAGNI," you said, confident you could sprinkle a few API calls here and there. But now, six months later, your once-pristine codebase is riddled with ad-hoc HTTP calls. Like an invasive species, these calls have spread through your business logic, impossible to remove without ripping out half the ecosystem.

"It’s fine," you thought, "HTTP is simple." You wrote a helper function to POST updates to the relevant services, proudly abstracting away the repetitive boilerplate. "What could go wrong?"

But alas! Your startup thrived. Your services grew, and suddenly everything wanted to know everything. "Who signed up?" "What action was performed?" "Did the user close the modal?" You were drowning in code churn, endlessly updating each service to notify its growing list of friends. There had to be a better way.

Then it hit you: **subscriptions.** What if services could just… register their interest in events? You could store subscribers in a database and notify them automatically. Elegant, you thought. So, you built a lightweight system to emit events and iterate over the subscribers, sending notifications as needed. Surely, this would be enough.

But then, something broke. A user created an account, but a dependent service missed the memo. Investigating, you discovered a service had received the POST but crashed before it could process it. No problem, you thought. You added a queue to track pending events and retry failed deliveries. It wasn’t RabbitMQ or Kafka—you were smarter than that. Your solution was simpler and better, surely.

Then came scaling. Polling your queue didn’t cut it anymore. Services were growing, pods were scaling dynamically, and now you needed to target specific processes. "What if I encode pod IDs in the event metadata?" you mused. "How elegant!" And just like that, you built a distributed messaging system.

But distributed systems are fragile. A process died mid-event. Another service deadlocked while waiting for a response. Chaos ensued. You added timeouts, retries, heartbeats, and state tracking to detect failures and recover gracefully. You even added live introspection tools to debug your increasingly opaque web of systems. "This is good engineering," you told yourself. "This solves real problems."

And then, you took a vacation. Naturally, something broke. Services hung, tables deadlocked, and timeouts triggered cascades of errors. Your teammates, staring at an indecipherable tangle of queues, retries, and state transitions, called you in to save the day. "This needs documentation!" you declared. You meticulously documented workflows, tightened APIs, and refactored your system into atomic, stateful workers. Surely, this would make things easier to reason about.

But now, here you stand. You’ve built:

  - An asynchronous, message-based runtime.
  - Supervision trees for fault-tolerant processes.
  - Lifecycle management for dynamic workers.
  - APIs for synchronous and asynchronous calls.
  - Live introspection tools for debugging.
  - A distributed message inbox (that still isn’t quite sharded right).

Dear friend, your journey, driven by a desire for simplicity and a refusal to use tools others had already perfected, has brought you full circle.

**Dear friend, you have built an Erlang.**

Addressed to,

Those who just wanted to trigger actions between their services.
