defmodule BlogWeb.RssController do
  use BlogWeb, :controller

  alias Blog.Posts

  require EEx

  plug :put_layout, false
  plug :put_root_layout, false

  @template_path Path.join([__DIR__, "rss_html", "index.xml.eex"])
  EEx.function_from_file(:defp, :render_rss, @template_path, [:assigns])

  def index(conn, _params) do
    posts = Posts.list_posts(is_draft: false, order_by: [desc: :published_at])

    xml = render_rss(%{posts: posts})

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, xml)
  end

  @doc """
  Formats a DateTime as RFC822 for RSS feeds.
  """
  def format_rfc822(nil), do: ""

  def format_rfc822(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%a, %d %b %Y %H:%M:%S GMT")
  end

  @doc """
  Returns the most recent publication date from a list of posts.
  """
  def latest_pub_date([]), do: format_rfc822(DateTime.utc_now())

  def latest_pub_date(posts) when is_list(posts) do
    posts
    |> Enum.map(& &1.published_at)
    |> Enum.reject(&is_nil/1)
    |> Enum.max(DateTime, fn -> DateTime.utc_now() end)
    |> format_rfc822()
  end
end
