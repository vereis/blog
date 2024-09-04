---
title: The Annual Blog Rewrite
slug: annual_blog_rewrite
is_draft: false
reading_time_minutes:
published_at: 2024-09-04 15:32:05Z
tags:
  - elixir
  - liveview
---

I've had some form of personal website ever since I was a kid. The early iterations were hosted on the now long defunct `Geocities` and `Angelfire`. I remember spending hours tweaking the HTML and CSS to get it just right.

During my university years, I started maintaining a website solely so I had something to show during job applications. At this point it was all static HTML/CSS/JS hosted on [Github Pages](https://pages.github.com/).

Since my time as a consultant at [Erlang Solutions](https://www.erlang-solutions.com/), I've been using [Elixir](https://elixir-lang.org/) and [Phoenix](https://www.phoenixframework.org/) to power my blog.

At the time, it was all just standard dead views and controllers, but I wanted to try out [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html), especially since the 1.0 release.

tl;dr -- if you're reading this, it works great !!

## The Old Blog

The old blog was a standard Phoenix app with a few controllers and views. I decided that having to handle markdown rendering and syntax highlighting was too much of a pain to set up.

Instead, I wrote all of my posts via [GitHub Issues](https://github.com/vereis/blog-old/issues) and used the [GitHub GraphQL API](https://developer.github.com/v4/) to:

1. Fetch the issues
2. Take the pre-rendered markdown body
3. Write it into [ets](https://www.erlang.org/docs/23/man/ets) which was my "database"

This worked well enough! I had a `GenServer` responsible for polling the GitHub API every 5 minutes and upserting the posts in the `ets` table.

The query itself looked something like this:

```graphql
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    nameWithOwner,
    issues(first: 10, orderBy: {field: CREATED_AT, direction: DESC}) {
      nodes {
        number
        bodyHTML
        createdAt
        updatedAt
        title
        labels(first: 10) {
          nodes {
            name
          }
        }
      }
      totalCount
    }
  }
}
```

And all I had to do was to process the response and write it into the `ets` table.

When a dead view was requested, I would fetch the post from the `ets` table and just interpolated the HTML into the view.

This was cool because I could leverage GitHub's markdown rendering and syntax highlighting, and GitHub already supported features like tags and reactions which I planned on building on top of.

However... the iteration cycle for writing and previewing posts was too slow. Sure, I could view them on GitHub, but I wanted to see them in the context of my blog.

I'm also a [neovim](https://neovim.io/) user, and I wanted to be able to write my posts in my editor of choice.

## The New Blog

I took the opportunity a few weeks ago to rewrite the blog from scratch using LiveView.

Unlike dead views, LiveView is a stateful connection to the server. This means that I can have a single connection open and update the page in real-time as I write my posts. My blog doesn't currently _actually leverage_ any real-time features, but I have a few fun things planned here.

> Note: if you're unfamiliar with LiveView, I highly recommend checking out the [official docs](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).
>
> It's like [HTMX](https://htmx.org/) or [LiveWire](https://laravel-livewire.com/), but better in pretty much every way.

I wanted to move away from GitHub Issues and decided the following:

1. I'd write my posts in markdown files with some frontmatter in my app's `priv` directory.
2. I'd parse the markdown and frontmatter (I tried several approaches by I settled on `YamlElixir` and `Md`) for this.
3. I needed a solution for syntax highlighting. It looked like doing this in the backend would limit my language choices, so I decided to use [highlight.js](https://highlightjs.org/) on the frontend instead for now.
4. [Oban](https://hexdocs.pm/oban/Oban.html) started supporting [sqlite](https://hexdocs.pm/oban/Oban.Storage.SQLite.html) so I wanted to play around with that.
5. I wanted to live reload my posts as I wrote them.

On start up, I'd start the "Importer" which would watch the `priv/posts` directory for changes. When a change was detected, it would parse the markdown and frontmatter and insert the post into the database.

Whenever the "Importer" ran, it would broadcast the new post to all connected clients via `Phoenix PubSub`.

I definitely want to add some more features to this blog, but I'm happy with the current state.

I'm slowly working through all my old posts and rewriting them in markdown. I'm also planning on adding a search feature and some more advanced filtering.

The previous blog engine was also run via a `SystemD` service, but with the new engine I wanted to play around with [fly.io](https://fly.io/) to eventually leverage their edge computing features in tandem with LiveView.

## Poke Around!

This blog, as usual, is open source. You can find the code on [GitHub](https://github.com/vereis/blog).

Please see the top level `README.md` for instructions on how to run the blog locally.

Happy hacking!
