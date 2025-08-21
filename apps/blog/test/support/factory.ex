defmodule Blog.Factory do
  @moduledoc "Factory for creating test data using ExMachina."

  use ExMachina.Ecto, repo: Blog.Repo.SQLite

  alias Blog.Images.Image
  alias Blog.Posts.Post
  alias Blog.Posts.Tag
  alias Blog.Projects.Project

  def tag_factory do
    %Tag{
      label: sequence(:tag_label, &"tag-#{&1}")
    }
  end

  def post_factory do
    %Post{
      title: sequence(:post_title, &"Post Title #{&1}"),
      slug: sequence(:post_slug, &"post-title-#{&1}"),
      raw_body: """
      This is a sample blog post body.

      ## Introduction

      Lorem ipsum dolor sit amet, consectetur adipiscing elit.

      ## Content

      Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
      """,
      is_draft: false,
      published_at: ~U[2023-07-22 14:03:00.000000Z],
      reading_time_minutes: 5
    }
  end

  def draft_post_factory do
    struct!(
      post_factory(),
      %{
        is_draft: true,
        published_at: nil
      }
    )
  end

  def redacted_post_factory do
    struct!(
      post_factory(),
      %{
        is_redacted: true
      }
    )
  end

  def image_factory do
    {:ok, temp_file} = Briefly.create(extname: ".png")

    # Create a minimal valid 1x1 PNG file
    png_data = <<
      # PNG signature
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      # IHDR chunk
      # length
      0x00,
      0x00,
      0x00,
      0x0D,
      # type
      0x49,
      0x48,
      0x44,
      0x52,
      # width = 1
      0x00,
      0x00,
      0x00,
      0x01,
      # height = 1
      0x00,
      0x00,
      0x00,
      0x01,
      # bit depth=8, color=2, compression=0, filter=0, interlace=0
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      # CRC
      0x90,
      0x77,
      0x53,
      0xDE,
      # IDAT chunk
      # length
      0x00,
      0x00,
      0x00,
      0x0C,
      # type
      0x49,
      0x44,
      0x41,
      0x54,
      # compressed data
      0x08,
      0x1D,
      0x01,
      0x01,
      0x00,
      0x00,
      0xFF,
      0xFF,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x01,
      # CRC
      0x73,
      0x75,
      0x01,
      0x18,
      # IEND chunk
      # length
      0x00,
      0x00,
      0x00,
      0x00,
      # type
      0x49,
      0x45,
      0x4E,
      0x44,
      # CRC
      0xAE,
      0x42,
      0x60,
      0x82
    >>

    File.write!(temp_file, png_data)

    %Image{
      name: sequence(:image_name, &"image-#{&1}.webp"),
      path: temp_file,
      data: "fake_binary_data",
      width: 800,
      height: 600,
      content_type: "image/webp"
    }
  end

  def post_with_tags_factory do
    %Post{
      title: "Post with Tags",
      slug: "post-with-tags",
      raw_body: "This post has tags associated with it.",
      is_draft: false,
      published_at: ~U[2023-07-22 14:03:00.000000Z],
      reading_time_minutes: 2,
      tags: build_list(2, :tag)
    }
  end

  def project_factory do
    %Project{
      name: sequence(:project_name, &"Project #{&1}"),
      url: sequence(:project_url, &"https://example.com/project-#{&1}"),
      description: sequence(:project_description, &"Description for project #{&1}")
    }
  end
end
