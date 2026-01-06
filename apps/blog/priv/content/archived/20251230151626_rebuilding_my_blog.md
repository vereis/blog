---
title: "Rebuilding My Blog"
slug: "rebuilding-my-blog"
published_at: 2025-12-30 15:16:00Z
is_draft: false
tags:
  - idk
---

I've always had a homepage or a blog of some sort, and I've always enjoyed tinkering with it.

My first few sites and blogs were built on an old platform called [Freewebs](https://www.freewebs.com) (RIP), which I used to host my very first website when I was about 8 years old.

Over the years, especially as I've become more competent at this web development thing, I've rebuilt my blog a few times.

My previous two iterations of my blog are probably the most notable, and span basically my entire employed career so far. For my own nostalgia, here's a quick summary of each.

## The First Blog

My first "professional" blog was written in 2019, shortly after I graduated from university and started my first job.

I managed to get a position as an [Erlang](https://erlang.org) and [Elixir](https://elixir-lang.org) consultant at [Erlang Solutions](https://erlang-solutions.com), which was amazing but fraught with learning.

After a few months of being "benched" (i.e. not having any billable work), they put me on a project to help bootstrap an innovation lab for a large international car manufacturer.

This was my first real exposure to Elixir in _any_ setting, and they used tech I had only ever heard of in passing:

- [Phoenix](https://phoenixframework.org)
- [GraphQL](https://graphql.org)
- [PostgreSQL](https://postgresql.org)
- [Kubernetes](https://kubernetes.io)

I learned a lot on that project, and I built some cool stuff.

I wanted to start documenting that kind of stuff somewhere, so I decided to improve my Phoenix skills by building a brand new blog from scratch.

### Stack

I didn't really know much about hosting stuff at the time, and managing my own database felt overwhelming. So I decided on the following setup:

- [Phoenix](https://phoenixframework.org) for the backend, all server-side rendered.
- [GitHub Issues](https://github.com) as a CMS (using [GitHub's GraphQL API](https://docs.github.com/en/graphql)) to fetch blog posts on demand).
- [A Raspberry Pi](https://www.raspberrypi.org) running at home to host the site.

I was proud of that setup. It worked well for what it was.

GitHub Issues made for a simple CMS, and I could write posts in Markdown and just open a new issue to publish them. GitHub would handle all the storage, markdown rendering, and even image hosting for me, and generally stuff "just worked" latency be damned.

The Raspberry Pi hosting setup was less than ideal. Power outages, network issues, and general maintenance became a constant headache.

Overall though, I learned a lot from that first blog, and it served me well for a few years.

I did make some improvements over time, like caching GitHub's API responses in memory using [ets](https://erlang.org/doc/man/ets.html) to speed things up, or hosting on [Gigalixir](https://gigalixir.com) instead of my Raspberry Pi, but the core architecture remained the same.

### Images

You can check out what this first version looked like below!

![Landing page](../assets/images/blog_1.webp)

Otherwise it stayed mostly the same (CSS redesigns aside -- I love tinkering with CSS).

I ended up using that blog for about three years, writing a fair few posts along the way (though not very good ones, looking back now).

Around the time [Tailwind CSS](https://tailwindcss.com) started becoming popular, I decided to retrofit it into my blog, which again was a great learning experience even if not much changed architecturally.

![Redesign](../assets/images/blog_2.webp)

## The Second Blog

In 2024, I decided the architecture of my first blog was limiting. Maybe I just wanted to build something new and shiny.

Around this time, I managed to buy `vereis.com` (for ~$900, yikes...), and to commemorate the occasion, I decided to build a brand new blog from scratch.

### A Better Stack

This time, I wanted to do things properly. My first blog was written when I was a graduate developer, whereas now I was a Tech Lead with years of experience under my belt.

I decided to build the entire site using:

- [Phoenix LiveView](https://phoenixframework.org) for the backend and frontend (no more server-side rendering!).
- [SQLite](https://sqlite.org) as the database, just to play around with something new.
- [Fly.io](https://fly.io) for hosting, because I wanted to try out their platform.

This new setup was a huge improvement over my previous blog, at least in _correctness_.

Now that I was using a proper database, I could store posts, tags, metadata, and all sorts of other stuff in a structured way.

Using Phoenix LiveView also meant that I could build a more dynamic and interactive frontend (which I'm still admittedly trying to figure out what exactly to do).

### A Better(?) Design

If you've visited my blog before, this is the version you're probably familiar with. It looked something like this:

![vereis.com](../assets/images/blog_3.webp)

I really wanted to go all-in on the terminal aesthetic, so I based the entire design around that idea.

The original version of `vereis.com` was built using Tailwind, too. This ended up being a mistake though, as 90% of the content I was serving was static, pre-rendered HTML, and I had to duplicate all my styles between components and Tailwind's `prose` plugin to get everything to look right.

This not only was a pain to maintain, but it also led to a lot of weirdly structured HTML that could be simpler if I just wrote plain CSS.

At the time, the Elixir ecosystem had a couple of limitations for what I wanted to do too, for example:

- Markdown was rendered using `Earmark`, which didn't support good (if any) syntax highlighting out of the box. It also generated "weird" HTML when it came to random spaces between elements, which made styling difficult.
- Components were still being iterated on heavily, and there wasn't a great, obvious way to build reusable components without a lot of boilerplate.
- Architecting your LiveViews was (and honestly still is) a bit nebulous, and I struggled to find a good pattern that worked for me.

I also resorted to lots of Regex tomfoolery to get things like code blocks, images, and other media to render properly, which was less than ideal.

Despite these limitations, I still learned a lot from building and maintaining this second version of my blog.

> Heck, I even hit the front page of [Hacker News](https://news.ycombinator.com) twice, **back to back**. Watching the traffic spike in real-time was exhilarating—and terrifying—but the free tier of Fly.io handled it like a champ.

I did build a couple of nice features though, like:

- Filesystem watchers to auto-reload posts when I updated them locally.
- Scrollspying for my table of contents.
- A CRT filter for the terminal aesthetic.
- Full-text search for my posts.

### Limitations and Feedback

There was definitely a lot of room for improvement, though.

For one, the design was too much. The terminal aesthetic was cool, but it made reading long-form content tiring on the eyes, especially with the 10pt pixelated font I was using.

Designing a mobile-friendly experience was also difficult (especially inheriting all the HTML cruft that had built up), and I never really got around to it properly.

Another issue was that the CRT filter, while cool, made the site feel a bit sluggish and unresponsive, especially on mobile devices.

> I actually got a fair bit of feedback about the CRT filter when I went viral on Hacker News. It wasn't toggleable at the time, and made everything very hard to read...
>
> Sorry about that, folks. My bad.

I also didn't like how much JavaScript I had to include to get simple things like syntax highlighting to work.

Most importantly, I think, is that I wanted to be able to implement features like analytics, comments, etc., which was difficult because I deployed everything as a single docker container to Fly.io and I relied on importing all my posts, assets, etc. on boot for the blog to function.

I had intended on setting up a dual database architecture using [PostgreSQL](https://postgresql.org) and [SQLite](https://sqlite.org) to separate dynamic content (like comments, analytics, etc.) from static content (like blog posts), but I never got around to it, and in hindsight, I think that would have been overkill for my use case.

## The New Blog

So... here we are, approximately a year later, and I've decided to rebuild my blog yet again. What else is the new year for, right?

### Goals

This time around, I have a few specific goals in mind:

- I needed to improve the reading experience, especially on mobile devices.
- I wanted to go back to basics with vanilla CSS, avoiding frameworks like Tailwind where possible.
- I needed a persistent datastore that could handle both static and dynamic content without much fuss.
- I wanted to experiment with new Elixir libraries and tools that have come out since I last built my blog.

I also didn't want to couple myself too strongly to any one hosting provider or platform, so I wanted to keep things as simple and portable as possible. That includes avoiding services like S3 for image hosting, or any other third-party services that could lock me in.

> This is ultimately because I want to spend a good chunk of 2026 experimenting with self-hosting my own infrastructure using [Tailscale](https://tailscale.com) and [NixOS](https://nixos.org), so I want to keep things flexible.
>
> I can always migrate to a more robust setup later on down the line.

### The Revised Stack

After a lot of consideration, I've decided on the following stack for my new blog:

- [Phoenix LiveView](https://phoenixframework.org) for the backend and frontend.
- [SQLite](https://sqlite.org) as the primary database, using [LiteFS](https://litestream.io/litefs/) for replication and durability.
- [Fly.io](https://fly.io) for hosting, at least for now.

Eventually, I might actually retire the LiveView frontend in favor of a React or Svelte frontend that uses a GraphQL API, but for now, LiveView works well enough for my needs.

Additionally, there's been a huge influx of (potentially new?) Elixir libraries and tools that I want to try out, including:

- [MDex](https://hex.pm/packages/mdex) for Markdown rendering with built-in syntax highlighting wrapping Rust libraries. Also lets you process the AST directly, which is neat.
- [Floki](https://hex.pm/packages/floki) for HTML parsing and manipulation, which should help me avoid Regex when processing Markdown output.
- [Vix](https://hex.pm/packages/vix) for image processing, which is a wrapper around the [libvips](https://libvips.github.io/libvips/) library.
- [Websockex](https://hex.pm/packages/websockex) for WebSocket clients, which I use to replace the HTTP polling I used for presence updates.

Learning from the previous blog, I've also decided to go all-in on splitting my routes into separate LiveViews, and now that components seem to be stable, as much of the UI as possible is built using reusable components.

### The New Design

For the new design, I've decided to go for a much cleaner and simpler aesthetic.

Its still heavily inspired by terminal UIs (arguably moreso than before), but I've opted for a more readable font, better spacing, and a more neutral color scheme.

![New Design](../assets/images/blog_4.webp)

The key changes I've made are largely internal, but from a user perspective, the main differences are:

- A toggleable CRT filter, so users can choose whether or not they want the effect.
- A more readable font
- Improved mobile responsiveness
- Better typography and spacing for long-form content

The previous version of the blog used `ex` units in CSS for as much of the layout as possible. At the time I was unaware of the fact that modern browsers now support `lh` and `ch` units, which are _perfect_ for emulating a terminal's character grid.

Everything is now based on `lh` and `ch`, which makes the layout much more consistent across different screen sizes and resolutions.

The mobile view has also been completely redesigned from the ground up, with a focus on readability and ease of navigation:

![Mobile View](../assets/images/blog_5.webp)

### The Assets Pipeline

One of the biggest pain points with my previous blog was the way I handled assets like images.

Assets, like posts, were automatically imported into SQLite on boot, and I relied on lots of regular expressions to parse and process HTML output from Earmark to get things like images, code blocks, etc. to render properly.

This time around, I decided to:

1) Formalize my `Blog.Resource` pipeline such that it can be implemented by `Blog.Posts`, `Blog.Assets`, etc.
    - Handle dependencies between resources properly (e.g. posts depend on assets).
2) Process assets of different types (so images get processed with `Vix`, etc.) before storing them in the database.
    - Images get optimized and converted to `WebP`.
    - Generate 6 byte [CSS-Only LPIQ](https://leanrada.com/notes/css-only-lqip/) placeholders for each image to improve perceived load times.
    - Store metadata like dimensions, mime types, etc. in the database.
4) Process Markdown using `MDex` and `Floki`
    - Use `MDex` to render Markdown to HTML with syntax highlighting.
    - Use `Floki` to parse the HTML and extract assets, code blocks, etc.
    - Replace asset references in the HTML with proper URLs to my asset serving endpoint.
    - Wrap images in links to their full-resolution versions, etc.
3) Pubsub updates to connected clients when new posts or assets are available.

This new pipeline has made it much easier to manage my content, and I no longer have to deal with messy Regex to get things to work.

> In the future, I'll probably move images and the likes to a CDN or object storage service, but for now, this works well enough for my needs.
>
> The fact that SQLite lives with my actual application means that latency is minimal, and its not like I'm serving a huge amount of traffic.

The `LPIQ` thing is super cool too. It basically means that while images are loading, a tiny, blurred-out version of the image is shown instead, which improves perceived load times significantly.

You can see an example of this in action below (the pixelation is from due to a small screenshot, but you get the idea):

![LPIQ Example](../assets/images/lpiq.webp)

### LiteFS

The other major change I've made is to use [LiteFS](https://litestream.io/litefs/) for SQLite replication and durability.

LiteFS is a lightweight filesystem that replicates SQLite databases to S3-compatible object storage in real-time.

This means that I can run multiple instances of my blog, and they all share the same SQLite database, without having to worry about data consistency or replication.

This is a huge improvement over my previous setup, where I had to rely on a single SQLite database that was stored on the local filesystem of any given Fly.io instance.

With LiteFS, I can now scale my blog horizontally, and I don't have to worry about data loss if a Fly.io instance goes down.

The way this works for my setup is that each Fly.io instance asks [Consul](https://www.consul.io) for a lease to become the primary writer for the SQLite database.

Once an instance has the lease, it can write to the database as normal. All other instances are read-only replicas that get their data from the primary instance via LiteFS.

This was a _relatively_ simple change to make, and the benefits are huge. Each instance can now serve read requests independently, and write requests are handled by the primary instance.

The main complexity comes from forwarding write requests to my primary instance.

To handle this, I actually wrote a small Elixir library called [EctoLiteFS](https://hex.pm/packages/ecto_litefs) that builds on top of my existing [EctoMiddleware](https://hex.pm/packages/ecto_middleware) library to forward write queries to the primary instance automatically.

On boot, each instance subscribes to an event stream from LiteFS itself (and falls back to filesystem level polling) to determine who the primary is. Once a node discovers that it becomes the primary, it writes a row to the database which gets replicated to all other nodes, informing them of the new primary's node name.

If that node name is clustered with the current node, then the current node then transparently forwards the write operation to the primary node using [Erlang's distributed messaging system](https://erlang.org/doc/reference_manual/distributed.html).

All of this is completely transparent to the rest of my application, and I can write to the database as normal without having to worry about where the writes are actually going.

### Other Improvements

Beyond the major changes outlined above, I've also made a few other improvements to the blog:

- Full-text search using SQLite's built-in FTS5 extension for anything that implements `Blog.Resource`.
- A proper tagging system for posts, with tag pages and tag clouds.
- ARIA attributes and better overall accessibility.
- More composable and reusable components.

What's firing me up is that this new blog is _way_ more maintainable than my previous versions.

The architecture is cleaner, the code is more modular, and I can easily add new features without having to worry about breaking existing functionality (I've even got unit tests now, woohoo!).

### What's Next?

There's still a lot of work to be done, of course.

I want to grow as a writer. Not just technically, but in expressing ideas, telling stories, making people _feel_ something when they read my work. That means writing more in 2026—archiving and reworking my older posts, finding my voice, and actually putting myself out there instead of hiding behind code snippets and architecture diagrams.

I definitely want to add more multiplayer features to the blog as well -- live reactions, comments, seeing who's reading what, watching other people's mouse cursors, etc. Fun stuff, because why not?

I also want to experiment with self-hosting my own infrastructure, ideally in full on Kubernetes clusters running on [Tailscale](https://tailscale.com) nodes, all managed with [NixOS](https://nixos.org).

Three blogs, seven years, and countless rewrites later, I think I've finally figured out what I'm building: not just a blog, but a home for my ideas—one that grows with me instead of getting torn down and rebuilt every time I do.

This version feels different. It feels _right_. And maybe that's because for the first time, I'm not just building a platform to showcase what I know—I'm building a space to figure out who I want to become.

Here's to 2026.
