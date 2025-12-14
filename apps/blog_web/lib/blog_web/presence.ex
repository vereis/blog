defmodule BlogWeb.Presence do
  @moduledoc """
  Provides real-time presence tracking for viewers across the site.

  This module tracks LiveView processes using Phoenix.Presence and broadcasts
  presence changes via PubSub. It supports multiple topics for site-wide and
  page-specific tracking.

  ## Topics

  - `"viewers:site"` - All active users across the entire site
  - `"viewers:page:home"` - Home page viewers
  - `"viewers:page:posts"` - Posts list viewers
  - `"viewers:page:post:<slug>"` - Individual post viewers
  - `"viewers:page:projects"` - Projects list viewers
  - `"viewers:page:gallery"` - Gallery viewers

  ## Usage

  In a LiveView:

      alias BlogWeb.Presence

      def mount(_params, _session, socket) do
        if connected?(socket) do
          Presence.track(self(), "viewers:site", socket.id, %{})
        end
        {:ok, socket}
      end
  """
  use Phoenix.Presence,
    otp_app: :blog_web,
    pubsub_server: Blog.PubSub

  @doc """
  Initializes the presence tracker state.

  This callback is optional but allows us to maintain custom state
  and react to presence changes.
  """
  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Handles presence metadata changes and broadcasts them to subscribed processes.

  This callback is invoked whenever there are joins or leaves in any presence topic.
  We broadcast these changes so that LiveViews can reactively update viewer counts.
  """
  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    # Calculate the current count for this topic
    count = map_size(presences)

    # Broadcast the updated count to all subscribers of this topic
    Phoenix.PubSub.local_broadcast(
      Blog.PubSub,
      topic,
      {:viewer_count_updated, topic, count}
    )

    # Broadcast individual join events
    for {_key, _presence} <- joins do
      Phoenix.PubSub.local_broadcast(
        Blog.PubSub,
        topic,
        {:viewer_joined, topic}
      )
    end

    # Broadcast individual leave events
    for {_key, _presence} <- leaves do
      Phoenix.PubSub.local_broadcast(
        Blog.PubSub,
        topic,
        {:viewer_left, topic}
      )
    end

    {:ok, state}
  end
end
