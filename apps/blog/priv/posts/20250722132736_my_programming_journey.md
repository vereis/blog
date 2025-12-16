---
title: My Programming Journey
slug: my-programming-journey
is_draft: false
reading_time_minutes:
published_at: 2025-07-22 13:27:36.650166Z
tags:
  - ahoy
---

As I've become more active in the programming community, I've been asked a few common questions:

- What was your journey into tech?
- How did you get to where you are today?
- What advice would you give to newcomers?

Instead of repeating this story across different platforms, I thought I'd reflect on the whole journey and share it here.

## My Early Childhood

I was born in [Kuala Lumpur](https://en.wikipedia.org/wiki/Kuala_Lumpur) in 1996, but spent most of my childhood as a nomad thanks to my father's work.

We never stayed anywhere long enough for me to develop lasting friendships or place-based memories.

I don't have stories like "I learned to ride a bike at this park" or "I played football with friends at this school."

Everything was transient, except for two constant companions: my PlayStation and the family computer.

### The PlayStation One

One core memory stands out: my third birthday, when my late aunt gave me a [PlayStation One](https://en.wikipedia.org/wiki/PlayStation_One).

All I had was a demo disc, but I played that [Crash Bandicoot 3: Warped](https://en.wikipedia.org/wiki/Crash_Bandicoot_3:_Warped) jetskiing minigame for *hours*.

That PlayStation came with me everywhere. It was my first introduction to computers and gaming.

> In the late 90s and early 2000s, Malaysia had a thriving piracy scene. You could walk into upmarket malls and find binders full of pirated CDs -- games, movies, software. I don't know if it was technically legal, but I remember getting piles of new games constantly.

I built up a massive library and played everything obsessively:

**PlayStation favorites:**
- Crash Bandicoot series
- Spyro the Dragon series
- Ape Escape

**PC games that left lasting impressions:**
- [StarCraft](https://en.wikipedia.org/wiki/StarCraft)
- [Half-Life](https://en.wikipedia.org/wiki/Half-Life_(video_game))
- [Counter-Strike](https://en.wikipedia.org/wiki/Counter-Strike)

I was fascinated by these digital worlds and wanted to understand how they worked.

> As cringy as it sounds, I'd say my games were my first long-term friends.
>
> Everything in my life was transient, but my games were always there.

### Formative Disappointment

When I was around 7, my father decided we needed to move to London for better education opportunities.

Before the permanent move, we did a reconnaissance trip and stayed with family who had something I'd never seen: a [PlayStation 2](https://en.wikipedia.org/wiki/PlayStation_2).

I managed to play games on it like:

- [Crash Bandicoot: The Wrath of Cortex](https://en.wikipedia.org/wiki/Crash_Bandicoot:_The_Wrath_of_Cortex)
- [Spyro: Enter the Dragonfly](https://en.wikipedia.org/wiki/Spyro:_Enter_the_Dragonfly).

I was expecting the same quality as the originals, but they just didn't feel right. Something was off with the physics, the level design, the whole experience.

During that trip, we hit local game stores that had sales on older PlayStation games. I found copies of the original Crash Bandicoot and Spyro The Dragon.

Since I couldn't read well yet, I thought these were brand new games I'd somehow missed.

I was completely disappointed.

Having started with Crash 3 and Spyro 2 -- arguably the peaks of their series -- going backwards felt like a massive downgrade.

Spyro 1 was boring. Crash 1 was brutally difficult and felt unfair.

That's when I had the thought that would define my career:

**"I could make this, but better."**

> The audacity of a 7-year-old, right?

But I was serious. I wanted to make games like the ones I loved, but without the frustrating bits. Not too difficult, not with weird physics, not boring.

I fired up the family computer and searched "how to make video games" using [Ask Jeeves](https://en.wikipedia.org/wiki/Ask_Jeeves), naturally.

## Game Maker Era

My searches led me to [Game Maker](https://en.wikipedia.org/wiki/GameMaker), a drag-and-drop game development tool. I think I downloaded version 5.3 or 6.

Game Maker should have been perfect, but I had no idea what I was doing.

It had a thriving community of open-source games and examples though. While I couldn't make anything myself initially, I could play these games and make custom levels and art assets.

My reading comprehension wasn't great yet, so I avoided documentation and tutorials, developing a completely organic learning process instead:

1. Download someone's open-source game
2. Play it and get stuck, or find sections too easy/hard
3. Edit levels to adjust difficulty
4. Maybe swap assets to make it a "Sonic" game
5. Share with friends and family

I was really proud of these franken-games I created. Eventually, my curiosity pushed me beyond just swapping art and editing levels -- I wanted to change how the games *behaved*.

### Accidental Programming

As I got older, I realized I could actually change the behavior of games, not just the levels.

Game Maker games used either:
- A drag-and-drop interface (like Scratch)
- A custom language called [GML](https://en.wikipedia.org/wiki/GameMaker_Language)

The drag-and-drop interface confused me, but when I looked at GML scripts, I realized something important: if you squinted, they kind of looked like English.

I figured out that `VK_LEFT` was a constant for keyboard input, that `x` and `y` were screen coordinates, that `if` statements only ran code when conditions were met.

My process evolved:

1. Download an open-source game
2. Want to disable a feature or change a value
3. Open the GML script and try to figure out what it does
4. Change the script and see what happens
5. If it breaks, try to figure out why

> In retrospect, this was probably the worst possible way to learn programming. I developed terrible habits and didn't understand fundamentals. But I was having fun and building intuition.

For four years (ages 9-13), I devoted myself entirely to making Sonic and Pokémon fan games.

> I also dabbled with [RPG Maker 2003](https://en.wikipedia.org/wiki/RPG_Maker_2003) and [RPG Maker XP](https://en.wikipedia.org/wiki/RPG_Maker_XP) during this period.

I don't remember a defining moment when I realized I enjoyed programming. It was always about making games -- programming was just another tool in my toolbox, like art or level design.

But I did think programming was the **special sauce** that made games actually work.

### The Breakthrough Moments

I still remember the euphoria of finally figuring out how to make custom levels in a Sonic game that stored level data in two-dimensional arrays.

I'd spent *months* trying to understand the structure. I could change individual tiles by guessing, but couldn't grasp the pattern well enough to create entirely new levels.

When arrays finally clicked (`"Oh! Arrays are just organized lists of data!"`), I felt like I could build anything.

The same thing happened with state machines when I tried to disable Knuckles' climbing ability. All the character states were managed by complex systems that seemed completely opaque.

When I finally understood how states and transitions worked, it was another breakthrough moment.

> Wrong as I was about being able to build anything, these breakthrough moments were incredibly motivating.

## High School Solutions

When I started secondary school, Game Maker transitioned from hobby to practical tool.

The school had ancient network infrastructure with shared drives but zero modern communication tools. No [instant messaging](https://en.wikipedia.org/wiki/Instant_messaging), no coordination between classes.

This was intentional: they didn't want us chatting during lessons.

### Game Maker Messenger

As an instant-messaging-addicted teenager, I needed a solution. So I built an [MSN Messenger](https://en.wikipedia.org/wiki/MSN_Messenger) clone in Game Maker.

It was hilariously janky:
- The `"server"` was a shared network folder
- Each user had their own text file for messages
- The client polled these files every few seconds
- Want to chat? Create a `file` with both usernames
- Want to send a message? `Append` to the file with a `timestamp`

It actually worked! We could have conversations, leave messages, even do group chats by creating files with multiple usernames.

The teachers had no idea: they just saw kids typing in what looked like a text editor.

### Wikipedia Gaming

Around this time, I learned enough [HTML](https://en.wikipedia.org/wiki/HTML) to be dangerous using WYSIWYG editors like [Dreamweaver](https://en.wikipedia.org/wiki/Adobe_Dreamweaver) and [FrontPage](https://en.wikipedia.org/wiki/Microsoft_FrontPage).

I discovered I could clone Wikipedia's interface by copying its source code and making edits.

Then I had a brilliant idea: replace all the Wikipedia content with embedded [Flash](https://en.wikipedia.org/wiki/Adobe_Flash) games.

We'd be in ICT class with the teacher thinking we're researching something educational on "Wikipedia," but we're actually playing games like Tetris or Snake. The teacher would walk by, see what looked like a legitimate educational site, and move on.

> This was my first taste of using programming for social engineering.

### Programming Partnership

Secondary school was where I met people who were equally passionate about creative projects.

Due to the school's ethnic cliques -- not outright racism, but definite self-segregation -- I ended up in classes with other Asian students.

There was this one kid (let's call him Alex) who I immediately butted heads with. We were both used to being "the smart one" and "the creative one" at our previous schools.

When we got assigned a history project about medieval warfare, we both wanted to win so badly that we reluctantly teamed up.

This project changed everything.

**First revelation:** Alex was a genuinely exceptional artist with savant-level talent.

I'd been "the best artist" in every previous class, but Alex was just... better. Significantly better.

This was my first encounter with not being the best at something I cared about. Instead of being inspired to improve, I basically gave up on art.

> Character flaw of mine: if I'm not going to be the best, it becomes hard to put in effort.

**Second revelation:** Alex also had game development aspirations.

Once we bonded over games, we became inseparable. We'd analyze everything:

- Why did [Ocarina of Time](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Ocarina_of_Time) feel better than other 3D Zeldas?
- What made [Tony Hawk's Pro Skater](https://en.wikipedia.org/wiki/Tony_Hawk%27s_Pro_Skater) so addictive?
- Why were some RPGs engaging while others felt like homework?

These weren't just casual chats -- we were reverse-engineering fun.

We made a pact: when we grew up, we'd start a game studio together. He'd handle art, I'd handle programming.

> Spoiler: that hasn't happened yet, but we recently reconnected!

### 3D and Systems

I also met an older student deeply involved in [Tribes 2](https://en.wikipedia.org/wiki/Tribes_2). The official servers were shut down, but the community had built an open-source master server to keep it alive.

Tribes 2 ran on the [Torque Game Engine](https://en.wikipedia.org/wiki/Torque_Game_Engine), which had an accessible scripting system. This was my first exposure to 3D game programming -- lighting systems, physics simulations, 3D models instead of 2D sprites.

More importantly, this friend taught me batch programming on Windows. We built a command-line Task Manager that could spawn processes, list running processes, and kill them by name.

**The real motivation?** Our school used spyware called "Vanguard" to monitor student computers. Our batch scripts could kill the monitoring process.

We felt like hackers.

> This was my first exposure to systems programming -- understanding how operating systems work, process communication, automation.

## The Academic Years

### Academic Misstep

When selecting A-levels, I made what was probably a strategic mistake. Instead of choosing subjects that would maximize university options, I picked ones that genuinely interested me:

- Philosophy/Ethics
- English Literature
- Art

This felt right at the time, but most high-ranking UK computer science programs required Further Mathematics, Physics, sometimes Chemistry.

I had none of these.

### Limited University Options

When application time came, I couldn't apply to Cambridge, Oxford, Imperial, UCL -- basically any prestigious program.

I ended up with offers from:
- University of Sussex: "Games and Multimedia Environments"
- University of Kent: Computer Science

Sussex was explicitly game-development focused, but I had a feeling I'd benefit more from learning computer science fundamentals rather than specific tools.

> I'd been making games for years but felt like I was just hacking things together.
>
> I didn't understand *why* my code worked, just that it did.

I chose Kent for Computer Science and this turned out to be incredibly lucky.

### Functional Discovery

The University of Kent has deep roots in functional programming research, with notable faculty including:

- **David Turner** (inventor of [Miranda](https://en.wikipedia.org/wiki/Miranda_(programming_language)))
  - Former head of the School of Computer Science
  - Pioneer in lazy functional programming languages
  - Influenced the design of [Haskell](https://en.wikipedia.org/wiki/Haskell_(programming_language))
- **[Simon Thompson](https://www.kent.ac.uk/computing/people/3164/thompson-simon)**
  - Co-authored definitive Erlang textbooks with Francesco Cesarini
  - Expert in functional programming and formal methods
  - Active researcher in programming language theory

I didn't know any of this when I started -- I just wanted to learn "real" programming.

### Culture Shock

The transition from self-taught to academic programming was rough.

I didn't know what **compiling** was. In Game Maker, you pressed `F5` and your game ran.

The idea that code had to be transformed by a separate program was foreign.

Basic terminology confused me. Game Maker calls **classes** objects and **objects** instances -- backwards from every other language.

I was comfortable with [Linux](https://en.wikipedia.org/wiki/Linux) thanks to my **ricing** hobby, but I'd never compiled from source or managed dependencies.

The first few weeks were humbling. I went from feeling competent to feeling like a complete beginner.

### Erlang Romance

The module that changed everything was "Functional and Concurrent Programming," taught by Simon Thompson.

Erlang was unlike anything I'd encountered:
- No loops -- everything was recursion
- No mutable variables -- everything was immutable
- No objects -- everything was functions and pattern matching

Coming from imperative languages, Erlang felt alien. I struggled hard initially.

But I'm stubborn and perfectionist, so I forced myself to use Erlang for every assignment where language choice was optional.

> Data structures homework? Erlang.
> Algorithms project? Erlang.
> Completely inappropriate assignments? Definitely Erlang.

This was educational masochism, but it worked. Through repetition, I not only learned Erlang -- I fell in love with it.

There's something beautiful about functional programming once it clicks. Complex systems emerge from simple, composable functions. Immutability eliminates whole categories of bugs. Pattern matching makes code read like mathematical proofs.

### Other Favorite Modules

**Compilers:** Learning how programming languages work under the hood. **Lexical analysis**, **parsing**, **code generation**.

**Theory of Computing:** **Formal logic**, **algorithm analysis**, **data structure design**.

**Natural Computation:** **Genetic algorithms**, **neural networks**, **swarm intelligence**.

### Final Year Project

I built an Erlang to JavaScript compiler -- letting people write Erlang code but run it in browsers.

The project was probably too ambitious for an undergraduate thesis. I had to implement:
- `Parser` for Erlang syntax subset
- `Type inference` for pattern matching
- `Code generation` for JavaScript
- `Runtime support` for Erlang's process model in browsers

I didn't finish everything I wanted, but I learned tremendously about language design and compilation.

More importantly, the project convinced me I wanted to work with Erlang professionally.

Armed with my compiler and a head full of functional programming theory, I felt ready to take on the world.

## Job Hunt Reality

I started applying for Erlang jobs with all the confidence of someone who'd forced Erlang into every possible use case.

This confidence was misplaced.

**Problem 1:** There aren't many Erlang jobs. The language is powerful for specific use cases (telecoms, distributed systems), but the market is small.

**Problem 2:** Companies using Erlang want senior engineers with production experience. They want people who understand OTP, who've debugged distributed systems, who know the ecosystem.

I knew university Erlang -- recursive functions, pattern matching, spawning processes. But I'd never built real systems with `OTP` supervisors, `gen_servers`, `applications`.

The gap between academic knowledge and production readiness was massive.

I applied to maybe a dozen Erlang shops and got... crickets.

### Serendipitous Email

In March 2017, my academic advisor emailed about volunteering at CodeMesh LDN. The message was casual: "Want to help at this alternative programming languages conference?"

I said yes because I had nothing better to do.

Only when I showed up did I realize what CodeMesh actually was.

CodeMesh London was one of the premier conferences for functional programming and distributed systems. The conference series has featured industry legends such as:

- [Joe Armstrong](https://en.wikipedia.org/wiki/Joe_Armstrong_(programmer))
- [Rich Hickey](https://en.wikipedia.org/wiki/Rich_Hickey)
- [Francesco Cesarini](https://www.linkedin.com/in/francescocesarini/)
- [Robert Virding](https://en.wikipedia.org/wiki/Robert_Virding)
- [Alan Kay](https://en.wikipedia.org/wiki/Alan_Kay)
- Many other luminaries in alternative programming languages

**Most importantly:** CodeMesh was organized by Erlang Solutions, *the* Erlang consultancy, founded by Francesco Cesarini.

Here's the beautiful coincidence: Francesco co-authored the definitive "[Erlang Programming](https://www.oreilly.com/library/view/erlang-programming/9780596803940/)" textbook with Simon Thompson -- my professor.

During volunteering, I mentioned to Francesco that I was Simon's student and had built an Erlang compiler.

A few weeks later: interview invitation from Erlang Solutions.

### Practical Interview

Instead of whiteboarding algorithms, they had me take their Erlang certification exam, which was a simple university-style exam with questions ranging from basic syntax to OTP concepts.

I spent the weekend before diving into `OTP` documentation, learning `gen_servers`, `supervisors`, `applications`, and I came out with enough of an understanding to get a passing score.

I was practically given the job on the spot, went out with the team for lunch, and the started as soon as summer break ended.

> Sometimes the universe just aligns perfectly.

## Consulting Deep End

Starting at a consultancy was perfect for learning.

Instead of one company's problems, I got exposure to remarkable variety -- different systems, industries, challenges.

Erlang Solutions' model was simple:

- **Consulting:** Work with clients to build or improve systems, if they needed Erlang or Elixir expertise, we had it.
- **Training:** Provide training courses on Erlang, Elixir, distributed systems, functional programming.
- **Products:** Develop and maintain open-source libraries and tools for the Erlang/Elixir ecosystem.
- **Community:** Organize conferences, meetups, and events to promote functional programming and distributed systems.

I mainly focused on the consulting side of things, which meant jumping into different projects every few months.

### Financial Services

My first project was implementing `The Demarcation Protocol` for a major UK financial services company -- a distributed, lock-free algorithm for increasing transaction throughput.

For my first professional programming project, I was:
- Implementing cutting-edge academic research
- Working with multi-datacenter distributed systems
- Handling financial transactions where bugs cost millions
- Using advanced Erlang/OTP features I'd only read about

It was terrifying and exhilarating.

The initial spec of the project was written by a senior engineer who had left the company. I was thrown straight in with the only goal being "make this work".

Thankfully, I had the help of another junior engineer who'd just joined, and we were able to leverage the expertise of other Erlang Solutions engineers, and Francesco directly.

When we got the system running, we had to demonstrate it to our clients. I managed to package the entire system into a simple release that could be run with `docker swarm`.

While Francesco was giving the presentation to our client, he handed the live demo over to me.

I managed to run the demo flawlessly, connecting a couple of nodes on my local laptop to some nodes running in the cloud and demonstrated significant numbers of current transactions per second even on commodity hardware!

> I was terrified, but honestly this was a defining moment in my career.
>
> I learned more in three months at ESL than in three years of university.

### Toyota Innovation Lab

Once the POC was done, I was offered a chance to join a very exciting project which involved Elixir rather than Erlang.

It was my first time touching Elixir, and I knew nothing about it other than the fact that it was as Kotlin is to Java, an alternative syntax with a slightly different feature set to Erlang.

The project was for Toyota's new European innovation lab focused on building mobility solutions beyond car sales.

Myself, and two other engineers were tasked with "bootstrapping" the lab itself, being the first technical hires, to help them build their first product.

The project was a B2B2C car sharing platform: think `Zipcar`, but white-labeled. Employees book cars through an app, unlock with their phone, drive around, return them.

This was my first IoT programming. Cars aren't just software -- they're physical objects with GPS, cellular connections, sensors, actuators. Software has to handle unreliable networks, battery drain, security concerns.

The entire project was an Elixir project leveraging `Phoenix` and `Absinthe` for APIs and `Kafka` for real-time processing.

It was my first taste of genuinely distributed programming, across AWS regions with sophisticated failure handling.

> Watching someone unlock a car using code I'd written was incredibly satisfying.
>
> Watching someone be unable to unlock a car because they were in the middle of the Australian outback with no signal was terrifying...

### Metal Trading

After a couple of years at Toyota, I was brought onto a third project which in many ways, seemed like a step back in complexity, but was actually a fascinating challenge.

The next project was working with a German metal trading company selling construction materials -- rebar, steel beams, aluminum sheets.

Their goal was to modernize their existing systems, which were a mix of legacy software and manual processes.

They had a `Rails` monolith handled everything through synchronous requests, and integrated with various manual email based workflows.

They had started building a new Elixir system to replace their monolith, but it was still in the early stages and only modelled flows synchronously.

They brought myself in to help a new ESL architect to build new asynchronous workflows that would hopefully help replace their existing monolith, and help provide asynchronous processing and APIs for their new management UI.

We rebuilt their workflow engine in Elixir using `OTP's` actor model. Each order became a long-running `process` that could handle state changes, communicate with APIs, send notifications, recover from failures.

We also started designing the system as a series of async-first domains which communicated to eachother via generic event broadcasts, and built a DSL wrapping `RabbitMQ` to make it easy to define and test.

This was my first time working on a non-greenfield project, and learning to mesh with an existing team and how to incrementally improve a codebase was a valuable experience.

### Cultural Lessons

Working at different companies exposed me to completely different software cultures:

**Financial services:** Correctness and compliance -- extensive testing, formal documentation, change approval processes.

**Toyota:** Experimental -- rapid prototyping, frequent iterations, willingness to throw away non-working code.

**Metal trading company:** Pragmatic -- just wanted reliable solutions without ceremony, focus on business value over technical purity.

Learning to adapt communication and technical approaches to different organizational cultures was **as valuable as technical skills**.

## Going Product

After just over three years at ESL, I decided I wanted to **own** a product rather than solving other people's problems.

I wanted to join a team and work on every facet of the product:

- Designing and building features
- Deployment and infrastructure
- Meeting with clients
- Iterating on feedback
- Architecting solutions

Consulting has this limitation: you're always working within someone else's constraints.

You build something cool, then leave and someone else maintains it.

I wanted the full lifecycle: **design, build, deploy, maintain, iterate, scale**.


Through my mentor who I met during the Toyota project, I got an opportunity to join a US based startup working remotely as their first "dedicated" hire.

> The startup at the time was still extremely early stage.
>
> I was the second engineer in the UK (after my mentor), and there were three other engineers including the CEO and founder.
>
> At this point in time, the other engineers had their salaries paid by the clients of the startup, and I was the first engineer to be paid by the startup itself.

### Tech Leadership

The transition from consultant to employee was smooth -- I'd always approached projects like a core team member anyway.

As the team grew and I moved into tech lead responsibilities rather organically, I tried to recreate what made ESL effective:

**Safe spaces to fail:** Give people challenging projects slightly beyond current capabilities, with enough support that `failure isn't catastrophic`.

**Exposure to complexity:** Junior developers learn faster on `real problems` rather than `toy projects`.

**Learning from mistakes:** Focus on understanding `why things went wrong` rather than assigning blame. The struggle to understand and fix errors is where deep learning happens.

> This brings me to a concern about the current **AI landscape**. Junior developers can get working code for almost any problem from ChatGPT.
>
> That's powerful, but it might short-circuit the very **struggle** that leads to deep understanding.
>
> Reading **docs**, reading **source code**, and **reasoning about failures** are the skills you build when the answer isn't immediate. They matter most when AI doesn't know the answer.

A lot of my time now is spent doing non-programming tasks. I definitely miss the days of just writing code and shipping it, though I still try to carve out time for that.

## Full Circle

Recently, I started building an MMO. A beautiful full-circle moment back to where this journey began.

I feel like I **"lost myself"** over the years. I got too focused on backend systems and business problems, too far from the creative drive that originally motivated me.

That's maybe incorrect, though. I do **love** what I do, and I love solving complex problems. That's why I didn't notice the shift in mindset.

But as I'm approaching my 30s, I've been in a reflective phase. I realized that the spark that got me into programming was always a means to an end: **making games**.

Now that I'm professionally comfortable, know what I'm doing (generally), and have time -- I want to revisit that original spark.

### Engineering an MMO

The approach is completely different from my Game Maker days. Instead of graphics and gameplay first, I'm approaching it like a distributed systems engineer.

MMOs are massive real-time databases with complex networking:

- **Low-latency messaging** between thousands of concurrent players
- **Persistent world state** surviving server crashes
- **Anti-cheat systems** in peer-to-peer environments
- **Scalable architecture** handling population spikes
- **Real-time spatial queries** for "who can see what"

This is exactly what **Erlang/OTP** was designed for:

- The **Actor model** maps to game entities
- **OTP supervision trees** handle fault tolerance and isolate domains
- **Distributed Erlang** enables seamless clustering

I'm building it like a backend engineer: **API-first design**, **comprehensive monitoring**, **automated testing**, **infrastructure as code**.

One problem I've always had with making games is that I never felt like I was doing **"important"** things.

This was probably due to my lack of polished art assets, music, or all the other things that make a game feel like a game.

As a result, I'd write plenty of engines and make lots of prototypes -- some admittedly quite fun -- but never had the drive or motivation to finish anything.

This time, I'm more than aware of this and approaching it differently.

I'll build the game as a backend engineer: **systems and architecture first**, then build the game on top of that.

> Working on this has reminded me why I fell in love with programming.
>
> It's not just about solving business problems -- it's about creating something that didn't exist before.

## Key Lessons

Looking back, a few themes stand out:

### Curiosity And Serendipity

The most important opportunities came from being **curious** (and **lucky**) about tangentially related things.

I happened to fall into the right university at the right time. There I learned **Erlang** and met the right people.

I happened to volunteer at **CodeMesh** because I thought "why not?" -- that led to my first job.

I happened to be put on the right projects. Chasing **variety** over anything else led me to learn so many different things.

None of these were planned, strategic moves. They were just me **following my curiosity** and being open to new experiences.

I truly think people should **embrace their own curiosity** and make the most of the moves you make, rather than trying to plan everything out.

Life (at least in my case), happens to figure itself out.

### Embracing Uncertainty

Alongside the serendipity of my journey, I learned to embrace uncertainty.

One of my core skills that differentiates me from many peers is that I'm **completely comfortable with unknowns**.

You should have a willingness to tackle problems you don't understand.

I don't know if this is a result of **how** I learned programming or just my personality. But I have faith in my skills -- they've gotten me this far, and I trust I'll figure things out as I go.

Sometimes the right thing is to **jump right in** -- you'll learn more from the struggle than any mentorship or tutorial.

### Skill Compounding

Software engineering is an extremely deep and broad field.

You can spend a lifetime learning and still only scratch the surface.

I'm personally an engineer who values **breadth of experience** over depth of understanding, so this takeaway might not apply to everyone, but...

The key takeaway: **skills compound over time**. The more you learn, the easier it is to learn new things.

The more concepts you learn, the more you might find them generally applicable to other domains.

If you look at my journey, you'll see how seemingly unrelated skills came together:

- Game development taught me high level project planning, user experience design, state management.
- Ricing (which is only tangentially related to programming) taught me Linux, shell scripting, automation, compiling, exposed me to open source, to many different programming languages and ways of doing things.
- Philosophy and literature classes gave me critical thinking skills, the ability to analyze complex systems, and a love for clear (ok, admittedly verbose and rambly) communication.

There's probably a lot more I've learned that I can't attribute to specific sources. But the key takeaway is that **everything you learn compounds**.

## What I'd Do Differently

**Look at tutorials earlier:** I spent years reinventing wheels and developing bad habits. Some exploration is valuable, but I went too far. I think this held me back somewhat.

**Learn fundamentals explicitly:** I picked up CS concepts through osmosis, which worked but was inefficient. Understanding **algorithms** and **data structures** earlier would have accelerated other learning.

**Network more intentionally:** The best opportunities came through personal connections, but those were largely accidental. Being more deliberate about building relationships would have opened more options.

**Write more:** I wish I'd started writing about programming earlier. **Writing clarifies thinking**, and published writing creates opportunities.

## Non-Traditional Advice

**University helps but isn't required:** My CS degree opened many doors, but outside of learning **Erlang**, I don't think I took very much away from it.

I'm glad to have experienced the classes and modules I did. I'm glad I know what **algorithmic complexity** or **context-free grammars** are, but I don't think I'm any better off at my job because of it.

University was a great way for me to serendipitously fall into a niche that became my entire career. But I don't think the academic portion was necessary.

If you're thinking about whether to go to university, the answer is: **it depends**.

If you're looking for actual learning, I'd say pick a project and build it. If you're looking for everything adjacent to that, then maybe it's worth it.

**Fundamentals matter more than frameworks:** Languages and frameworks change constantly, but **data structures**, **algorithms**, and **system design** are stable. Invest in understanding these deeply.

**Build things you care about:** Projects that taught me most were ones I was genuinely excited about, not ones that looked good on resumes.

If you look at my career path, you could argue I moved from more complex, **"impressive"** projects to simpler, more **"normal"** ones.

But the key is that there are still plenty of learning opportunities in "normal" projects. There are great lessons, great people, great experiences to be had.

Sometimes chasing **interesting** or **complex** projects can lead to burnout or inability to finish anything.

I'm personally happy making do with what I have and finding joy and satisfaction in that.

When that fails you, try a side project!

## Conclusion

A career in programming isn't a straight line. Mine started with a simple desire: to make better games.

As accomplished, or experienced as I am now, I still haven't nearly achieved that goal, but I have learned so much along the way.

I'm personally looking forward to the next chapter of my journey, and I hope this reflection helps others on their own journeys.
