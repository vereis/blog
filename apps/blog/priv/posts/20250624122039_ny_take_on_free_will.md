---
title: My Take On Free Will
slug: my-take-on-free-will
is_draft: false
reading_time_minutes:
published_at: 2025-06-24 12:20:39Z
description: |
  Like my post on consciousness, this is another topic I've held consistent beliefs about for most of my life.

  I don't believe free will exists, quantum mechanics doesn't save us, and this post covers why that's actually liberating.
tags:
  - philosophy
---

`Free will` is one of those topics that gets people **really** worked up.

A lot of people seem to dislike this notion, but I don't understand why—I don't believe `free will` exists.

> Though I don't think it **really matters**... more on this later.

I've held this belief consistently since I was a kid. I was never religious, but while I was in school, I couldn't reconcile the idea that "God" gave us `free will` despite being `omniscient`.

I mean, if God knows everything, then he knows what you're going to do before you do it, right? So how can you have `free will`?

I never found a satisfactory answer to this question, and I still don't think there is one.

That aside, from that point on, I started questioning why it is that people **assumed** that `free will` exists?

What actually implies that we have `free will`?

Well, before diving into that, let's first define what `free will` is.

## Definition

When I talk about `free will`, I'm referring to the ability to make choices `at will`:

- Without being constrained by the **laws of physics**.
- Without being biased by an actor's **past experiences**.
- Without being affected by **genetics** or other factors **outside of the actor's control**.

This is a pretty strict definition, but I think it's the only one that makes sense.

The first point, in particular, is extremely important.

The idea that an actor "could have chosen otherwise" is a common argument for `free will`, but it doesn't hold up under scrutiny.

Time travel to the past is impossible, so in reality, all choices ever made have been singular and unrepeatable by nature.

> Unless you believe in some form of multiverse, but that's a topic for another day. Regardless, choices in **this** universe are singular and no alternatives exist.

If you can't **test** whether someone could indeed have "chosen otherwise", then the statement is meaningless, but I'm getting ahead of myself...

## Schools of Thought

There are many definitions of `free will`, but I'm going to focus on my definition above.

As such, my later arguments may not hold if you define `free will` differently.

There are three primary philosophical positions regarding `free will`:

> If you want to dive deeper into these philosophical schools, I recommend reading [Free Will by Sam Harris](https://www.samharris.org/books/free-will) for a compelling hard determinist perspective.

### Libertarianism

This is the belief that `free will` genuinely exists.

Libertarians believe that humans have the ability to make choices that aren't determined by prior causes or external factors.

Maybe not every choice, but at least some choices are made freely and independently of any prior influences.

Typical justifications for this belief include appealing to some `quantum indeterminacy` which we'll talk about shortly, or the idea that humans have a `soul` or `spirit` that allows for free decision-making.

> Note that this is not the same as the political ideology of the same name.

### Compatibilism

Compatibilists, or `soft determinists`, believe that `free will` exists, but only in a limited sense -- that is, they believe that `free will` can coexist with `determinism`.

Compatibilists argue that even if our choices are influenced by prior causes or external factors, we can still be considered to have `free will` as long as we are not coerced or forced into making a choice.

Per my definition of `free will`, this position doesn't work as it effectively only focuses on the **absence of coercion**, so being `determined` by the laws of physics does not count as a violation of `free will` in the compatibilist view.

### Hard Determinism

Hard determinists believe that `free will` does not exist at all.

This is the belief that `free will` is entirely incompatible with `determinism`, and that all choices are determined by prior causes or ultimately by the laws of physics.

I'll spend much of this post arguing for this position, so I won't go into too much detail here.

## Laplace's Demon

There's a classic thought experiment that illustrates the idea of hard determinism, known as `Laplace's Demon`.

> For a fascinating exploration of this concept, check out [The Quantum Universe by Brian Cox](https://www.amazon.com/Quantum-Universe-Anything-Happen-Does/dp/0306821443) which covers both classical and quantum determinism.

Imagine a hypothetical being, often referred to as `Laplace's Demon`, who knows the precise location and momentum of every atom in the universe at a given moment.

If this being exists, it could use the laws of physics to predict the future and retrodict the past with perfect accuracy.

As Laplace himself famously said:

> For such an intellect nothing would be uncertain, and the future, just like the past, would be present before its eyes.

To demonstrate this a little bit, let's consider a simple example from the programming world.

[Erlang](https://www.erlang.org/) is a functional programming language that is known for its concurrency model and fault tolerance, but for this argument, we will focus on its deterministic nature.

Functions in `erlang` are `pure`, meaning that they always produce the same output for the same input, and they have no side effects.

This means that if you know the input to a function, you can predict its output with certainty.

```erlang
-module(determinism).
-export([random_number/0]).

random_number() ->
    random:uniform(100).
```

In the above example, the `random_number/0` function generates a random number between 1 and 100. The thing is, when I started programming in `erlang`, I was surprised to learn that calling this function multiple times would always yield the same result.

```erlang
1> c(determinism).
{ok,determinism}
2> determinism:random_number().
10

% Restart Shell
1> c(determinism).
{ok,determinism}
2> determinism:random_number().
10
```

This is because every "process" in `erlang` has a piece of hidden state which is used to seed the random number generator.

This means that if you know the state of the process, you can predict the output of the function with certainty.

The same mechanism applies to running unit tests in [Elixir](https://elixir-lang.org/) -- tests by default are run in a "random" order, but you're able to pass in a seed to the test runner, which will ensure that the tests are run in the same order every time.

This is very useful for debugging, as it allows you to reproduce the same test failures consistently, but it also illustrates the deterministic nature of the language.

> I believe in modern `erlang`, calling `random:uniform/1` will yield different results every time as it internally updates the seed of the caller process, but the point still stands.

I believe that this is a good analogy for the idea of hard determinism:

- Objects without any forces acting on them stay like that.
- Objects change their state only when acted upon by external forces.
- If you know an object's state, you can predict future state.
- This applies to the universe as a whole.

> Of course, quantum mechanics and chaos theory complicate this picture.
>
> The thought experiment still illustrates the basic idea of hard determinism, however, and I'll address these complications later.

## The Illusion of Choice

Every day, we experience what feels like `deliberation`.

We weigh options, consider consequences, and `decide` on a course of action.

In short, we feel like we are making choices. But are we really?

I'd argue that **weighing options** and **considering consequences** are themselves determining acts, and that the `decision` we make is simply game theoretic optimization of the outcome of those acts.

Let me illustrate this with a simple example:

```erlang
-module(person).
-export([loop/1]).

% should be spawned in a separate process, loops forever making choices and updating
% a person's context as they go
loop(Context) ->
    receive
        {choose, Options} ->
            {BestOption, NewContext} = choose(Options, Context),
            io:format("Best option chosen: ~p~n", [BestOption]),
            loop(NewContext)
    end.

% makes a choice based on the current context of a person
choose(Options, Context) ->
    WeightedOptions = lists:map(fun Option -> {Option, weight(Option, Context)} end, Options),
    case lists:keysort(2, WeightedOptions) of
        [] -> error(no_options);
        [{BestOption, _}|_] -> {BestOption, update_context(BestOption, Context)}
    end.
```

In this example, we have a `person` module that represents a person making choices.

The `loop/1` function receives a list of options and chooses the best one based on the current context of the person.

The `choose/2` function calculates the weight of each option based on the context and returns the best option along with an updated context.

Note that the "best" option at any given time is determined by the `Context`, which is updated after each choice.

The `Context` might include factors such as:

- Past experiences
- Current state of mind
- External influences (e.g., social pressure, environment)
- Genetic predispositions

This means that the choice made is not truly `free`, but rather a result of the context in which the person finds themselves.

That context is itself a product of prior causes, which means that the choice is ultimately determined by those prior causes.

## Agency vs Free Will

It's crucial to distinguish between `agency` and `free will`.

I believe humans, and other animals, have `agency` -- the ability to perceive your environment, identify goals, and take actions to achieve those goals.

In this sense, many things exhibit `agency`:

- [E. coli](https://en.wikipedia.org/wiki/Escherichia_coli)
  - a simple bacterium, can move towards nutrients and away from toxins.
- [Slime molds](https://en.wikipedia.org/wiki/Slime_mold)
  - can solve mazes and optimize paths to food sources.
- [Claude Code](https://claude.ai/)
  - can analyze data, make predictions, and optimize algorithms.

But `agency` does not **imply** `free will`. It just means that you have heuristics and feedback mechanisms that help you optimize towards some goal.

We are sophisticated agents compared to the above examples, but we're still driven by our biological programming:

- We have a desire to survive, reproduce, and thrive.
- We enjoy comfort, pleasure, and social interaction.
- We avoid pain, discomfort, and social isolation.

These drives influence our choices, but they do not imply that we have `free will`.

I would argue that it is more accurate to say we are **slaves** to this programming than masters of it.

Even if you consider that a human might retaliate and fight back against their biological programming, that in itself is a **reaction** to the programming, not a choice made freely.

## Quantum Indeterminacy

As stated above, one of the common arguments against [Laplace's Demon](#heading-laplace's-demon) is that it only holds in a classical universe.

What this means is in classical physics -- i.e. Newtonian or even Einsteinian physics -- the universe is indeed deterministic per the argument.

However, in quantum mechanics, things are not so clear-cut.

Quantum mechanics introduces the concept of `indeterminacy`, where certain events cannot be predicted with certainty, even if we know the initial conditions.

> I'm not a physicist, but the idea is that at the quantum level, particles can exist in multiple states simultaneously until they are observed or measured.
>
> There's a lot of content around this, so I won't regurgitate it here, but the key takeaway is that quantum mechanics is inherently probabilistic.

Because of this `indeterminacy`, some argue that the universe is not deterministic, and therefore there are mechanisms by which `free will` can exist.

> The indeterminacy of quantum mechanics has been tested and confirmed through various experiments, and it **is** a fact.
>
> Some people used to believe that quantum mechanics could be determined by hidden variables, but the [Bell's theorem](https://en.wikipedia.org/wiki/Bell's_theorem) has shown that this is not the case.
>
> I'll talk more about this later, but for now, let's focus on the implications of quantum indeterminacy for `free will`.

This is not an idea that I subscribe to, so let's explore why.

### Randomness vs Free Will

If we **assume** that quantum mechanics introduces genuine randomness into the universe, then we have to ask ourselves: "Does this randomness imply `free will`?"

I would argue that it does not.

Randomness does not equate to `free will`. Just because something is random does not mean that it is a choice made freely, it just means that the outcome is unpredictable.

Rolling a die doesn't give the die `free will` or `agency`, it just means the outcome is random.

### Probabilistic Outcomes

The thing is... quantum mechanics isn't **random** in the same way that rolling a die is random.

Quantum mechanics is probabilistic, meaning that while we cannot predict the outcome of a single event with certainty, we can predict the statistical distribution of outcomes over many events.

Even if we were to admit that quantum mechanics introduces some level of indeterminacy, it does not follow that this indeterminacy allows for `free will`, for all possible outcomes could still be calculated and assigned probabilities.

This means that while we may not be able to predict the outcome of a single event, we can still understand the underlying probabilities and distributions that govern those events.

### Quantum Decoherence

Another argument against the idea that quantum mechanics allows for `free will` is the concept of `decoherence`.

Decoherence is the process by which quantum systems lose their quantum properties and behave classically due to interactions with their environment.

This means that while quantum mechanics may introduce indeterminacy at the quantum level, the macroscopic world we experience is still governed by classical physics.

As such, the idea that quantum mechanics allows for `free will` is undermined by the fact that we do not experience quantum indeterminacy in our everyday lives.

We, being macroscopic objects, are subject to the laws of classical physics, which are deterministic in aggregate.

## Superdeterminism

I'm actually what you might call a `superdeterminist`.

I believe that everything that has happened, is happening, and will happen was determined by the initial conditions at the Big Bang and the causal chains that followed.

[Superdeterminism](https://en.wikipedia.org/wiki/Superdeterminism) is a philosophical position that tries to reconcile the apparent randomness of quantum mechanics with the idea of determinism.

### Bell's Theorem

Bell's theorem is a fundamental result in quantum mechanics that shows that certain predictions of quantum mechanics are incompatible with the idea of local hidden variables.

> For a deep dive into Bell's theorem and its implications, I highly recommend [Speakable and Unspeakable in Quantum Mechanics by J.S. Bell](https://www.amazon.com/Speakable-Unspeakable-Quantum-Mechanics-Collected/dp/0521523389) himself, or for something more accessible, [Quantum Reality by Nick Herbert](https://www.amazon.com/Quantum-Reality-Beyond-New-Physics/dp/0385235690).

It essentially states that if quantum mechanics is correct, then the universe must be non-local, meaning that events can be correlated in ways that cannot be explained by local hidden variables.

The problem with this is that Bell's theorem relies on an axiomatic assumption known as `measurement independence`, which states that the choice of measurement settings is independent, i.e. two observers can run their own experiments in different locations, times, places, and that experiment outcomes are not influenced by each other.

### Measurement Independence

Measurement independence is a crucial assumption in Bell's theorem, but it is not necessarily true.

If we assume that the universe is deterministic, then the choice of measurement settings could be influenced by prior causes, meaning that the measurement settings are not independent.

All things are connected, at least in the sense that they are part of the same causal chain, so the choice of measurement settings could be influenced by the initial conditions of the universe.

The superdeterminist position is that the apparent randomness of quantum mechanics is a limitation or a result of our understanding of the universe (or its initial conditions).

For the `erlang` example above, we don't know the `seed` of the random number generator, so we cannot predict the output of the function -- it looks random to us, but that's precisely because we don't have access to the underlying state of the system.

### The Universal Wave Function

While quantum mechanics talks about wave functions of particles and systems, I'd argue that these are just human-scale approximations of the true state of the universe.

In the superdeterministic view, the idea that individual particles have their own wave functions is misleading -- there's only one wave function that describes the entire universe at any point in time.

The individual wave functions quantum physicists talk about and work with are just approximations of subsets of the universal wave function -- the best we can do but not the whole picture.

## The Evolution of Choice

You might wonder: if `free will` is an illusion, then why do we feel like we have it?

The answer, in my opinion, lies in the evolution of choice.

The ability to make choices has been a crucial survival mechanism for our ancestors, and not all choices are made in a vacuum:

- Are you hungry? Dying of starvation?
- Do you already have a stockpile of food?
- Are you being chased by a predator?

These are all factors that influence our choices, though they themselves follow deterministic patterns.

They are factors that require an agent to short-circuit the decision-making process and make perhaps suboptimal (or even irrational) choices in order to survive.

This is where the illusion of `free will` comes into play.

Per my post on [consciousness](/posts/my_take_on_consciousness), we may be `conscious` of our choices, but we're not actually in the driver's seat.

We're "witnessing" the choices (and the short-circuiting of them) as they happen, but they're still not being made freely, and they're not influenced by our "conscious" experience.

The actual computational process of weighing options, considering consequences, and making decisions also happens at a level that is not accessible to our conscious mind:

- You "choose" to breathe, but you don't consciously control it normally.
- You "choose" to blink, but you don't consciously control it normally.

These are all examples of "choices", or at least actions, that are hard **requirements** for survival, so the need to short-circuit their decision-making process was never an evolutionary requirement.

> Actually, if you think about the ability of humans to swim, you can see why there are **cases** where we do consciously control our breathing, but this is a learned behavior and not the default.
>
> Same for blinking, which is usually an involuntary action, but can be consciously controlled.

Consider how we experience decision-making: you're presented with options, you feel yourself deliberating, and then you "decide."

But neuroscience suggests this is backwards.

Your brain begins processing and moving toward a decision before you're consciously aware of deliberating. The conscious experience is more like a delayed readout of what your neural networks have already begun computing.

> The classic studies on this are Benjamin Libet's experiments from the 1980s. For modern perspectives, read [The Illusion of Conscious Will by Daniel Wegner](https://mitpress.mit.edu/9780262731621/the-illusion-of-conscious-will/).

This explains why the illusion is so compelling.

Evolution didn't design us to understand our own mechanisms -- it designed us to survive and reproduce.

The feeling of choice motivates the complex behaviors that keep us alive, even though the "choice" itself is just awareness of a process that was already determined.

## Systems Determining Systems

One beautiful aspect of determinism is how it explains the persistence and evolution of human institutions:

```erlang
-module(society).
-export([evolve/1]).

-record(society, {
    laws,
    education,
    individuals,
    future_state
}).

evolve(#society{individuals = Individuals} = Society) ->
    % Some individuals are determined to uphold traditions
    % Others are determined to rebel and change things
    % The tension between these creates societal evolution
    Contributions = lists:map(fun(Person) ->
        contribute_to_society(Person, Society)
    end, Individuals),

    FutureState = lists:foldl(fun merge_social_forces/2, #{}, Contributions),
    Society#society{future_state = FutureState}.

contribute_to_society(Person, Society) ->
    % Implementation depends on person's context and society's state
    #{person => Person, influence => calculate_influence(Person, Society)}.

merge_social_forces(Contribution, Acc) ->
    % Combine individual contributions into collective change
    maps:merge_with(fun(_K, V1, V2) -> V1 + V2 end, Contribution, Acc).
```

Education, religion, law, and culture are all systems that were determined by our ancestors and now determine us.

Some of us are determined to preserve these systems, others to change them, still others to abolish them entirely.

This creates fascinating feedback loops.

The people who created our current educational system were shaped by their own education, which was shaped by the education systems before that, stretching back through history.

Each generation slightly modifies the system, but those modifications are themselves determined by the complex interplay of genetics, previous experiences, and cultural pressures.

```erlang
-module(cultural_evolution).
-export([new/1, next_generation/1]).

-record(cultural_evolution, {
    generation = 0,
    cultural_values
}).

new(InitialConditions) ->
    #cultural_evolution{cultural_values = InitialConditions}.

next_generation(#cultural_evolution{generation = Gen, cultural_values = Values} = State) ->
    NewGen = Gen + 1,

    % Each generation is shaped by the previous
    Educators = select_educators(Values),
    Rebels = select_rebels(Values),
    Conformists = select_conformists(Values),

    % The new values emerge from the tension between these groups
    NewValues = synthesize(Educators, Rebels, Conformists),

    % But this synthesis is itself determined by the personalities
    % and circumstances that were determined by previous generations
    State#cultural_evolution{
        generation = NewGen,
        cultural_values = NewValues
    }.

select_educators(Values) ->
    % Some people are determined to preserve and transmit culture
    lists:filter(fun has_carriers/1, Values).

select_rebels(Values) ->
    % Others are determined to question and change things
    % Often because of their specific life experiences
    Problems = identify_problems(Values),
    lists:map(fun generate_solution/1, Problems).

has_carriers(Value) ->
    % Check if this cultural value has people willing to preserve it
    maps:get(carriers, Value, []) =/= [].

identify_problems(Values) ->
    % Find issues with current cultural values
    lists:filter(fun(Value) -> maps:get(problematic, Value, false) end, Values).

generate_solution(Problem) ->
    % Create new cultural values to address problems
    #{solution_to => Problem, innovative => true}.

synthesize(Educators, Rebels, Conformists) ->
    % Combine the influences of all groups
    lists:flatten([Educators, Rebels, Conformists]).
```

This explains why social change happens gradually rather than through sudden revolutionary breaks.

Even the most radical revolutionaries are shaped by the systems they're rebelling against. Their critiques, their proposed solutions, their methods of change—all are products of their determined development within existing systems.

It also explains why certain ideas emerge independently in multiple places.

When the underlying conditions are similar, similar minds will be shaped in similar ways, leading to similar insights and innovations.

## Practical Implications

I don't think the existence or non-existence of `free will` changes how we should live our lives, but there are a few implications worth considering.

### The Ethics Question

One of the most common objections to hard determinism is the ethical implications.

If we don't have `free will`, then how can we hold people accountable for their actions?

> This was actually tried in the 19th century, when some philosophers argued that criminals should not be punished, but rather rehabilitated, as they were not truly responsible for their actions.

The answer is simple: punishment and moral responsibility serve societal functions regardless of free will.

This is doubly true per the above section on `Systems Determining Systems`.

```erlang
-module(criminal_justice_system).
-export([punish_criminal/2]).

-define(PURPOSE, maintain_social_order).

punish_criminal(Criminal, Crime) ->
    % Not because they "chose" evil
    % But because punishment serves multiple functions:

    Punishment = determine_punishment(Crime),

    % These all serve the system's purpose
    deter_others(Punishment),          % Biases future behavior
    protect_society(Criminal),         % Removes dangerous individuals
    satisfy_victims(Punishment),       % Maintains social cohesion

    % The criminal was determined to commit the crime
    % Society is determined to respond with punishment
    % Both are playing their roles in a larger system
    {punished, Criminal, Punishment}.

determine_punishment(Crime) ->
    % Calculate appropriate response based on crime severity
    #{
        type => maps:get(punishment_type, Crime, fine),
        severity => maps:get(severity, Crime, low),
        duration => maps:get(duration, Crime, days)
    }.

deter_others(Punishment) ->
    % Signal to society that certain behaviors have consequences
    broadcast_consequence(Punishment).

protect_society(Criminal) ->
    % Remove or rehabilitate dangerous individuals
    case is_dangerous(Criminal) of
        true -> isolate(Criminal);
        false -> rehabilitate(Criminal)
    end.

satisfy_victims(Punishment) ->
    % Provide sense of justice to maintain social cohesion
    notify_victims(punishment_served, Punishment).
```

Criminals should be punished not because they freely chose evil, but because they failed to reason in accordance with societal rules.

They knew what they were doing and knew the consequences if caught. Punishment serves as a mechanism to bias others not to commit similar crimes.

As there are no free beings, we judge all determined beings equally. That's enough.

### Personal Relationships

My deterministic beliefs don't make me treat people poorly or give up on relationships. If anything, they make me more stoic and accepting.

> If this resonates with you, I'd recommend exploring [Letters from a Stoic by Seneca](https://www.amazon.com/Letters-Penguin-Classics-Lucius-Annaeus/dp/0140442103) for practical wisdom on accepting what you cannot control.

When someone hurts me, I understand they were determined to act that way by their experiences, psychology, and circumstances.

This doesn't excuse harmful behavior, but it helps me respond more rationally and less emotionally.

I still form preferences about how I want to be treated, and I still communicate those preferences.

The fact that these interactions are determined doesn't make them meaningless.

> In fact, understanding determinism can improve relationships. Instead of getting angry at someone for being "selfish" or "inconsiderate," I can try to understand what factors led to their behavior.
>
> This doesn't mean accepting bad treatment or avoiding boundaries. It just means approaching relationship problems more systematically and less personally.

### Why Argue if Free Will Doesn't Exist?

Minds can be changed -- by other minds, through determined processes of reasoning and evidence presentation.

Some people are determined to be convinced by good arguments, others aren't. I'm determined to try.

## Conclusion

Free will is one of humanity's most persistent illusions, but it's still an illusion.

We are sophisticated biological machines, executing incredibly complex programs written by evolution, culture, and experience.

The fact that we experience this execution subjectively doesn't make us the programmers.

I find this view both intellectually honest and practically liberating.

Just as I concluded in my consciousness post: let's be whimsical and explore the universe around us—including the mechanisms of our own minds.

The fact that we're determined to do so doesn't make the journey any less fascinating.

## Further Reading

If this post sparked your interest, here are some books that shaped my thinking on these topics:

- **[Determined by Robert Sapolsky](https://www.amazon.com/Determined-Science-Life-without-Free/dp/0525560971)** - A comprehensive look at how biology and environment shape behavior
- **[The Fabric of the Cosmos by Brian Greene](https://www.amazon.com/Fabric-Cosmos-Space-Texture-Reality/dp/0375727205)** - Excellent exploration of space, time, and the nature of reality
- **[Thinking, Fast and Slow by Daniel Kahneman](https://www.amazon.com/Thinking-Fast-Slow-Daniel-Kahneman/dp/0374533555)** - How our minds actually make decisions (spoiler: not consciously)
