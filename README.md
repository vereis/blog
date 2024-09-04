# Blog

This is a minimal blog leveraging [Elixir](https://elixir-lang.org/) and [Phoenix](https://www.phoenixframework.org/).

![image](https://github.com/user-attachments/assets/b6ca53bc-ba5e-4040-b54f-e6a3a53502a2)

## Structure

This project is set up as an umbrella project with the following applications:

- `blog_web`: The Phoenix web application containing all web-related logic.
- `blog`: The Elixir application containing all business logic.

Notably, `blog_web` is set up to use [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html) for real-time updates. At the time of writing only live routes are being used.

### Blog

The `blog` application contains all business logic. This includes the following:

- `Blog.Schema`: Custom schema implementation used in lieu of `Ecto.Schema`, providing easy query composition and other conveniences.
- `Blog.Posts`: The context module for posts. This module contains functions for creating, updating, and deleting posts.
    - `Blog.Posts.Post`: The schema module for posts. This module contains the schema for posts.
    - `Blog.Posts.Tag`: The schema module for tags. This module contains the schema for tags.
    - `Blog.Posts.Importer`: The module for importing posts.
    - `Blog.Posts.Reloader`: Publishes messages to any connected viewers to trigger live updates.
- `Blog.Migrator`: Boots up on application startup and is responsible for running migrations.

Posts are stored in SQLite and are imported from the `priv/posts` directory.

Currently whenever posts are updated, we stream all posts from thr source directory and upsert them into the database if they've been modified. The implementation is still naive and could be optimized.

### BlogWeb

The `blog_web` application contains all web-related logic. Phoenix comes with a lot of boilerplate, but we're leveraging the built in Tailwind support.

The only notable part of the web application is the `BlogWeb.PostLive` module, which is responsible for rendering the UI.

The only JavaScript being used outside of the included `liveview.js` is the `highlight.js` library for syntax highlighting. This will be removed in future.

### Running the project

You should be able to run the project by running the following commands (assuming Elixir is installed):

```sh
mix deps.get
mix do ecto.drop, ecto.create, ecto.migrate
iex -S mix phx.server
```

You can visit the blog locally via `localhost:4000` in development.

If you use `nix`, this project includes a `flake.nix` to get you set up, and a `.envrc` for direnv integration. The env vars in the `.envrc` are recommended to be sourced before running.

### Writing Posts

Posts are written in Markdown and stored in the `priv/posts` directory. The filename should be in the format `YYYYMMDDHHMMSS_slug.md`. The file should contain the following frontmatter:

```markdown
---
title: The Title of the Post
slug: the_slug
is_draft: false
reading_time_minutes: 5
published_at: 2024-09-04 15:04:13Z
tags:
  - elixir
  - liveview
---
```

A `Mix.Task` is provided to create posts. You can run the following command to create a new post:

```sh
mix gen.post blog_post_slug is_draft=true tags=elixir,liveview
```

All frontmatter fields support being overrided by a command line argument in the format `key=value`. The `tags` field should be a comma separated list.

## Building

To build the project, you can run the following command:

```sh
MIX_ENV=prod mix release
```

This will create a release in `_build/prod/rel/blog`. Follow instructions to start.

You can also run the project in a Docker container. To do so, you can run the following commands:

```sh
docker build .
docker run -p 4000:4000 <image_id>
```

## Deployment

This project is set up to be deployed to [Fly](fly.io). You can deploy the project by running the following commands:

```sh
flyctl launch; flyctl deploy
```

This will deploy the project to Fly. You can then visit the blog at the URL provided by Fly.

Alternatively, you can deploy the application manually or create a Systemd service to run the application. This is not set up by default but you can use the release created above to do so.

## Future work

This project is a playground for me so I'm planning to add the following features:

- [ ] Public metric gathering and reporting
- [ ] RSS feed
- [ ] Search functionality
- [ ] Mobile friendly UI
- [ ] "Fun" features like active viewers, likes, reactions, etc.
- [ ] Comments
- [ ] Simple chat

## License

This project is licensed under the MIT license. See the `LICENSE` file for more information.

## Contributing

Contributions are unexpected but welcome! Feel free to open an issue or a pull request.

I'll make issues for any features I'm planning to add, so feel free to pick one up if you're interested.
