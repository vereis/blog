defmodule Blog.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Blog.Repo

  alias Blog.Posts.Post
  alias Blog.Projects.Project
  alias Blog.Tags.Tag

  def post_factory do
    %Post{
      title: sequence(:post_title, &"Post Title #{&1}"),
      slug: sequence(:post_slug, &"post-title-#{&1}"),
      raw_body: """
      # Sample Post

      This is a sample blog post body with some content.

      ## Introduction

      Lorem ipsum dolor sit amet, consectetur adipiscing elit.

      ## Content

      Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      """,
      body:
        ~s(<h1 id="sample-post">Sample Post</h1><p>This is a sample blog post body with some content.</p><h2 id="introduction">Introduction</h2><p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p><h2 id="content">Content</h2><p>Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>),
      excerpt: ~s(<p>This is a sample blog post body with some content.</p>),
      reading_time_minutes: 1,
      headings: [
        %Post.Heading{level: 1, title: "Sample Post", link: "sample-post"},
        %Post.Heading{level: 2, title: "Introduction", link: "introduction"},
        %Post.Heading{level: 2, title: "Content", link: "content"}
      ],
      is_draft: false,
      published_at: ~U[2024-01-01 12:00:00Z]
    }
  end

  def project_factory do
    %Project{
      name: sequence(:project_name, &"Project #{&1}"),
      url: sequence(:project_url, &"https://github.com/vereis/project-#{&1}"),
      description: "A sample project description that explains what this project does."
    }
  end

  def tag_factory do
    %Tag{
      label: sequence(:tag_label, &"tag-#{&1}")
    }
  end
end
