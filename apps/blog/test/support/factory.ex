defmodule Blog.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Blog.Repo

  alias Blog.Content.Asset
  alias Blog.Content.Content
  alias Blog.Content.Link
  alias Blog.Content.Permalink
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

  # Content schemas factories

  def content_factory do
    %Content{
      slug: sequence(:content_slug, &"essays/sample-content-#{&1}"),
      type: "essays",
      title: sequence(:content_title, &"Sample Content #{&1}"),
      source_path: sequence(:content_source_path, &"priv/content/essays/sample-content-#{&1}.md"),
      raw_body: """
      # Sample Content

      This is sample content for testing.

      ## Section

      More content here.
      """,
      body:
        ~s(<h1 id="sample-content">Sample Content</h1><p>This is sample content for testing.</p><h2 id="section">Section</h2><p>More content here.</p>),
      excerpt: ~s(<p>This is sample content for testing.</p>),
      reading_time_minutes: 1,
      is_draft: false,
      published_at: ~U[2024-01-01 12:00:00Z]
    }
  end

  def asset_factory do
    %Asset{
      slug: sequence(:asset_slug, &"assets/sample-image-#{&1}.webp"),
      content_slug: nil,
      source_path: sequence(:asset_source_path, &"priv/content/assets/sample-image-#{&1}.png"),
      name: sequence(:asset_name, &"sample-image-#{&1}.webp"),
      data: <<137, 80, 78, 71, 13, 10, 26, 10>>,
      data_hash: sequence(:asset_hash, &"abc123#{&1}"),
      content_type: "image/webp",
      metadata: %Asset.Metadata.Image{
        width: 800,
        height: 600,
        format: "webp"
      }
    }
  end

  def content_link_factory do
    %Link{
      source_slug: sequence(:link_source, &"essays/source-#{&1}"),
      target_slug: sequence(:link_target, &"essays/target-#{&1}"),
      context: "body"
    }
  end

  def content_permalink_factory do
    %Permalink{
      path: sequence(:permalink_path, &"/posts/old-slug-#{&1}"),
      content_slug: sequence(:permalink_target, &"essays/new-slug-#{&1}")
    }
  end
end
