defmodule BlogWeb.Components.Header do
  @moduledoc """
  Site header components including navigation and branding.
  """
  use Phoenix.Component

  @doc """
  Renders the site-wide navigation bar with links to main sections.

  ## Examples

      <.navbar current_path="/" />
  """
  @taglines [
    "now with 100% more bugs",
    "works on my machine",
    "it's a feature, not a bug",
    "shaving yaks since 2003",
    "undefined is not a function",
    "segfault (core dumped)",
    "let it crash!",
    "nix fixes this",
    "powered by elixir",
    "powered by erlang",
    "hot code reloading, #yolo",
    "recursion: see recursion",
    "i use nixos, btw",
    "i use vim, btw",
    "now with added tail calls",
    "i like the crt filter stfu",
    "404 tagline not found",
    "semicolons are optional",
    "i use hhkbs, btw",
    "you don't need types",
    "type systems solve nothing",
    "powered by liveview",
    "ssr'd baby",
    "desktop view is prettier",
    "probably incompetent...",
    "still better than js",
    "javascript > typescript, btw",
    "i use opencode, btw",
    "my other car is a tesla",
    "help i'm trapped in a computer",
    "certainly!",
    "absoltely!",
    "added comprehensive unit tests",
    "reporting you to the authorities",
    "i solemnly swear that i am up to no good",
    "as a LLM, i cannot assist with that request",
    "this is prompt injection, btw",
    "websockets, btw",
    "htmx but better, btw",
    "powered by rust tm (no, seriously)"
  ]

  attr :current_path, :string, default: "/"

  def navbar(assigns) do
    assigns = assign(assigns, :taglines_json, Jason.encode!(@taglines))

    ~H"""
    <div class="site-header">
      <div class="site-header-row">
        <.link navigate="/" class="site-title">vereis.com</.link>
        <div class="site-header-crt">
          <BlogWeb.Components.Checkbox.checkbox
            id="crt-filter-toggle-mobile"
            storage_key="crtFilter"
            body_class="crt-filter"
            label="CRT Filter"
          />
        </div>
      </div>
      <p
        class="site-tagline"
        id="site-tagline"
        phx-hook=".Typewriter"
        phx-update="ignore"
        data-taglines={@taglines_json}
      >
        <span class="tagline-text"></span><span class="tagline-caret">█</span>
      </p>
    </div>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".Typewriter">
      export default {
        mounted() {
          this.taglines = JSON.parse(this.el.dataset.taglines)
          this.lastTagline = null
          this.typeRandomTagline()

          // Re-type on LiveView navigation
          this.handlePageLoad = () => {
            this.typeRandomTagline()
          }
          window.addEventListener("phx:page-loading-stop", this.handlePageLoad)
        },

        destroyed() {
          if (this.handlePageLoad) {
            window.removeEventListener("phx:page-loading-stop", this.handlePageLoad)
          }
          if (this.currentTimeout) {
            clearTimeout(this.currentTimeout)
          }
        },

        typeRandomTagline() {
          // Cancel any in-progress typing
          if (this.currentTimeout) {
            clearTimeout(this.currentTimeout)
          }

          const textEl = this.el.querySelector('.tagline-text')
          if (!textEl) return

          let text
          do {
            text = this.taglines[Math.floor(Math.random() * this.taglines.length)]
          } while (this.taglines.length > 1 && text === this.lastTagline)
          this.lastTagline = text

          textEl.textContent = ''
          let i = 0

          const type = () => {
            if (i < text.length) {
              textEl.textContent += text.charAt(i)
              i++
              this.currentTimeout = setTimeout(type, 30 + Math.random() * 50)
            }
          }
          type()
        }
      }
    </script>

    <hr class="header-separator" />

    <nav class="site-nav">
      <.link navigate="/" class={nav_link_class(@current_path, "/")}>Home</.link>
      <span class="nav-separator">|</span>
      <.link navigate="/posts" class={nav_link_class(@current_path, "/posts")}>Posts</.link>
      <span class="nav-separator">|</span>
      <.link navigate="/projects" class={nav_link_class(@current_path, "/projects")}>
        Projects
      </.link>
    </nav>
    """
  end

  defp nav_link_class(current_path, link_path) do
    active? =
      if link_path == "/" do
        current_path == "/"
      else
        String.starts_with?(current_path, link_path)
      end

    if active?, do: "nav-link nav-link-active", else: "nav-link"
  end
end
