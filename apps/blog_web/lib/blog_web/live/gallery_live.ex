defmodule BlogWeb.GalleryLive do
  @moduledoc false
  use BlogWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1>Component Gallery</h1>
      <p>Preview of available components and their variants.</p>

      <section>
        <h2>Icons</h2>
        <p>ASCII/Unicode icons for terminal aesthetic:</p>
        <div class="icon-gallery">
          <div class="icon-item">
            <.icon name="info" />
            <code>info</code>
          </div>
          <div class="icon-item">
            <.icon name="error" />
            <code>error</code>
          </div>
          <div class="icon-item">
            <.icon name="close" />
            <code>close</code>
          </div>
          <div class="icon-item">
            <.icon name="spinner" class="icon-spin" />
            <code>spinner</code>
          </div>
        </div>
      </section>

      <section>
        <h2>Flash Messages</h2>
        <p>Flash notifications for user feedback:</p>
        <div class="component-preview">
          <.flash kind={:info} title="Info Flash">
            This is an informational message.
          </.flash>
          <.flash kind={:error} title="Error Flash">
            This is an error message.
          </.flash>
        </div>
      </section>

      <section>
        <h2>Navigation</h2>
        <p>Site navigation component:</p>
        <div class="component-preview">
          <.navbar />
        </div>
      </section>
    </Layouts.app>
    """
  end
end
