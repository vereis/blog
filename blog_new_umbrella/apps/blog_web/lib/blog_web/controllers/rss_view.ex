defmodule BlogWeb.RssView do
  @moduledoc false
  use BlogWeb, :xml

  def pub_date(nil) do
    ""
  end

  def pub_date(unix) when is_integer(unix) do
    DateTime.from_unix!(unix)
  end

  def pub_date(post) when is_list(post) and length(post) > 0 do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> min(Enum.max_by(post, &DateTime.to_unix(&1.published_at)))
    |> pub_date()
  end

  def pub_date(post) when is_list(post) do
    format_rfc822(DateTime.utc_now())
  end

  def pub_date(post) do
    format_rfc822(post.published_at)
  end

  def format_rfc822(date_time), do: Calendar.strftime(date_time, "%a, %d %b %Y %H:%M:%S %Z")

  embed_templates "rss_xml/*"
end
