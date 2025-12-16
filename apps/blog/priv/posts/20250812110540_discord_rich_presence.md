---
title: Discord Rich Presence
slug: discord-rich-presence
is_draft: false
reading_time_minutes:
published_at: 2025-08-12 11:05:40.395945Z
tags:
  - windows
  - nix
  - elixir
---

I'm a self-proclaimed [Elixir](https://elixir-lang.org/) enthusiast, and as a result, this blog is powered by [Phoenix](https://phoenixframework.org/) and [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html).

This let's me do some really cool, dynamic things, but until recently, I wasn't really using LiveView for any particular reason -- this blog could easily be a static site with a few pages.

In order to play around with LiveView more, I wanted to add a feature that would allow visitors to see what I'm currently playing, listening to, or working on in real-time.

This is easier said than done since I'm also developing in [WSL2](https://docs.microsoft.com/en-us/windows/wsl/) on [NixOS](https://nixos.org/) -- you can think about this as a docker container -- whereas my host operating system is Windows.

> I also really care about how I manage my system, so practically everything is managed through [Nix](https://nixos.org/).
>
> This includes my Windows applications which I bridge between WSL and Windows via wrapping [`winget.exe`](https://docs.microsoft.com/en-us/windows/package-manager/winget/) commands as part of my nixos builds.
>
> I love making life more difficult for myself for the sake of purity!

I can get metadata about my current activity via [Discord Rich Presence](https://discord.com/developers/docs/rich-presence/how-to), but I needed to bridge the gap between my WSL development environment and the Discord client running on Windows.

What I ended up building is a three-layer system that's much more sophisticated than just "Discord Rich Presence in WSL":

- **Layer 1**: A WSL bridge using [`npiperelay`](https://github.com/jstarks/npiperelay) and [`socat`](http://www.dest-unreach.org/socat/) to connect Neovim to Discord
- **Layer 2**: An Elixir backend that polls [Lanyard](https://github.com/Phineas/lanyard) for Discord status
- **Layer 3**: Real-time LiveView components that display my current activity on [vereis.com](https://vereis.com)

The result? Visitors can see exactly what I'm coding, when I'm online, and what I'm listening to, all updating live without page refreshes.

And since it's all managed through Nix, the entire setup is declarative and reproducible.

## The Multi-Layer Challenge

Getting Discord Rich Presence working across system boundaries revealed several interconnected problems that each needed elegant solutions.

### WSL Boundary Problem

Discord Rich Presence uses Inter-Process Communication (IPC) through Windows named pipes at `//./pipe/discord-ipc-0`.

WSL processes can't directly access Windows named pipes, so traditional Discord RPC libraries just fail silently.

Even if they could connect, most assume the Discord client is running on the same system as your editor.

### API Integration Challenge

Even if I got Rich Presence working locally, how do I get that data onto my website?

I need a reliable way to fetch Discord status from an external service, handle API failures gracefully, and update the data frequently enough to feel "live" without hammering Discord's API.

### Real-Time Updates Requirement

I want visitors to see updates immediately when I switch files, start coding, or change my Discord status.

This means WebSockets or similar real-time technology, plus a way to broadcast updates to multiple concurrent website visitors.

> Thankfully, Phoenix LiveView provides a great foundation for real-time updates, but I still need to get the data flowing into it.

### Declarative Configuration

As someone who manages their entire system through [Nix](https://nixos.org/), I can't have a solution that requires manual setup steps or imperative configuration.

Everything needs to be declared in my [`nix-config`](https://github.com/vereis/nix-config) repository and "just work" when I rebuild my system.

The solution I built addresses each of these constraints through a layered approach where each layer has a single, well-defined responsibility.

## Layer 1: The WSL Bridge

The first challenge was getting Discord IPC to work across the WSL boundary. This is where [npiperelay](https://github.com/jstarks/npiperelay) comes in.

### What is npiperelay?

`npiperelay` is a tool that allows WSL processes to access Windows named pipes.

It's essentially a bridge that takes standard input/output and forwards it to a Windows named pipe, or vice versa.

### The Bridge Solution

My solution uses `socat` to create a UNIX domain socket that `cord.nvim` can connect to, then forwards that connection through `npiperelay` to Discord on Windows:

```bash
socat UNIX-LISTEN:/tmp/discord-ipc-0,fork EXEC:"npiperelay.exe //./pipe/discord-ipc-0"
```

This creates a UNIX socket at `/tmp/discord-ipc-0` that any Discord RPC client can use as if Discord were running locally in WSL.

### Smart vim() Wrapper Function

Rather than manually managing this bridge, I created a wrapper function that automatically handles the setup.

Whenever I launch Vim, I want to ensure the bridge is set up correctly.

I created a custom `vim()` function that checks if we're in WSL, starts the bridge if needed, and then launches Neovim:

```bash
# If in WSL, when launching vim, set up `npiperelay` to forward stdin/stdout to Windows
vim() {
  if [ -n "$WSL_DISTRO_NAME" ]; then
    if ! pidof socat > /dev/null 2>&1; then
        [ -e /tmp/discord-ipc-0 ] && rm -f /tmp/discord-ipc-0
        socat UNIX-LISTEN:/tmp/discord-ipc-0,fork \
            EXEC:"npiperelay.exe //./pipe/discord-ipc-0" 2>/dev/null &
    fi
  fi

  if [ $# -eq 0 ]; then
    command nvim
  else
    command nvim "$@"
  fi
}
```

This function:
- Detects if we're running in WSL using `$WSL_DISTRO_NAME`
- Checks if the bridge is already running with `pidof socat`
- Cleans up any stale socket files
- Starts the bridge in the background
- Passes through all arguments to the real `nvim` command

### cord.nvim Configuration

With the bridge in place, configuring [cord.nvim](https://github.com/vyfor/cord.nvim) is refreshingly simple. In my Neovim configuration:

```lua
return {
  'vyfor/cord.nvim',
  build = ':Cord update'
}
```

That's it.

No special WSL configuration needed - `cord.nvim` just sees the UNIX socket and assumes Discord is running locally.

### Nix Integration

The Nix configuration ties it all together:

```nix
# Add required packages
home.packages = [
  socat  # For the bridge
  # ... other packages
];

# Install npiperelay binary
home.file.".local/bin/npiperelay.exe" = {
  executable = true;
  source = ../../bin/npiperelay.exe;
};

# Remove vim aliases to use our wrapper
programs.neovim = {
  enable = true;
  # viAlias = true;      # Commented out
  # vimAlias = true;     # Commented out
  # vimdiffAlias = true; # Commented out
};
```

The beauty of this approach is that it's completely transparent.

The bridge starts when needed and stays out of the way.

## Layer 2: Lanyard Backend Integration

Getting Discord Rich Presence working locally was only half the battle.

To display my activity on my website, I needed a way to fetch Discord status from an external service.

### What is Lanyard?

[Lanyard](https://github.com/Phineas/lanyard) is a service that exposes Discord user presence data through a REST API and WebSocket.

You connect your Discord account, and Lanyard provides endpoints like [`https://api.lanyard.rest/v1/users/{USER_ID}`](https://api.lanyard.rest/v1/users/175928847299117056) that return JSON with your current status, activities, and Spotify listening data.

### The Elixir Architecture

I built a GenServer-based system to integrate with Lanyard:

```elixir
# apps/blog/lib/blog/lanyard.ex - Main API
defmodule Blog.Lanyard do
  alias Blog.Lanyard.Connection
  alias Blog.Lanyard.Presence

  defdelegate get_presence(), to: Presence
  defdelegate has_presence?(), to: Presence
  defdelegate refresh_presence(), to: Connection

  def get_user_id, do: Application.fetch_env!(:blog, :lanyard_discord_user_id)
  def poll_interval, do: Application.fetch_env!(:blog, :lanyard_poll_interval)

  def api_url(user_id \\ nil) do
    base = Application.get_env(:blog, :lanyard_api_url, "https://api.lanyard.rest/v1/users")
    case user_id do
      nil -> base
      id -> "#{base}/#{id}"
    end
  end
end
```

### HTTP Polling

The [`Connection`](https://github.com/vereis/blog/blob/master/apps/blog/lib/blog/lanyard/connection.ex) GenServer handles API polling with exponential backoff:

```elixir
# Simplified polling logic
def handle_info(:poll, state) do
  case fetch_presence() do
    {:ok, presence_data} ->
      if presence_data != state.last_presence do
        update_state(presence_data)
      end

      timer = Process.send_after(self(), :poll, Lanyard.poll_interval())
      {:noreply, %{state | status: :connected, last_presence: presence_data, poll_timer: timer}}

    {:error, reason} ->
      Logger.error("Failed to fetch presence: #{inspect(reason)}")
      timer = Process.send_after(self(), :poll, 5000)  # Retry sooner on error
      {:noreply, %{state | status: :error, poll_timer: timer}}
  end
end

defp update_state(presence_data) do
  {:ok, presence} = Presence.update_presence(presence_data)
  Phoenix.PubSub.broadcast(Blog.PubSub, "lanyard:presence", {:presence_updated, presence})
end
```

### ETS-Backed Presence State

The [`Presence`](https://github.com/vereis/blog/blob/master/apps/blog/lib/blog/lanyard/presence.ex) GenServer manages state in an [ETS](https://www.erlang.org/doc/man/ets.html) table for concurrent reads:

```elixir
defmodule Blog.Lanyard.Presence do
  use GenServer

  # Fast ETS read - no GenServer messaging required
  def get_presence do
    case :ets.lookup(__MODULE__, :current_presence) do
      [{:current_presence, presence_data}] -> presence_data
      [] -> disconnected()
    end
  rescue
    ArgumentError -> disconnected()
  end

  def handle_call({:update_presence, presence_data}, _from, state) do
    presence_struct = from_api_data(presence_data)
    :ets.insert(__MODULE__, {:current_presence, presence_struct})
    {:reply, {:ok, presence_struct}, state}
  end
end
```

The ETS table has `read_concurrency: true` enabled, so multiple processes can read presence data simultaneously without contention.

This might be overkill, but whenever my live view mounts, it'll fetch the presence data from the ETS table, which is extremely fast and can scale to many concurrent visitors without performance issues, even on [fly.io](https://fly.io/)'s free tier.

### Supervision Strategy

A simple [supervisor](https://github.com/vereis/blog/blob/master/apps/blog/lib/blog/lanyard/supervisor.ex) ensures the system stays running, and boots everything up alongside the rest of my application:

```elixir
defmodule Blog.Lanyard.Supervisor do
  use Supervisor

  def init(_opts) do
    children = [
      Blog.Lanyard.Presence,    # Must start first
      Blog.Lanyard.Connection   # Depends on Presence
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

> I'm currently using HTTP polling, but I plan to switch to WebSocket connections in the future for lower latency and reduced API usage.

## Layer 3: Real-Time LiveView Integration

The final piece is displaying the presence data on my website with real-time updates. This is where Phoenix LiveView shines.

### PubSub Subscription

The [`BlogLive`](https://github.com/vereis/blog/blob/master/apps/blog_web/lib/blog_web/live/blog_live.ex) LiveView subscribes to presence updates during mount:

```elixir
def mount(_params, _session, socket) do
  Phoenix.PubSub.subscribe(Blog.PubSub, "lanyard:presence")

  socket = assign_new(socket, :presence, fn -> Lanyard.get_presence() end)
  {:ok, socket}
end

def handle_info({:presence_updated, presence}, socket) do
  {:noreply, assign(socket, :presence, presence)}
end
```

### Presence UI Components

I created several LiveView components to display different aspects of my presence:

**Online Status Indicator:**
```elixir
def status_indicator(%{presence: %Lanyard.Presence{}} = assigns) do
  {status, tooltip} = case assigns.presence do
    %{connected?: true, discord_status: "online"} -> {"status-online", "Online"}
    %{connected?: true, discord_status: "idle"} -> {"status-idle", "Idle"}
    %{connected?: true, discord_status: "dnd"} -> {"status-dnd", "Do Not Disturb"}
    %{connected?: true, discord_status: "offline"} -> {"status-offline", "Offline"}
    _disconnected -> {"status-disconnected", "Disconnected"}
  end

  assigns = assign(assigns, status: status, tooltip: tooltip)

  ~H"""
  <span class={["status-indicator", @status]} data-tooltip={@tooltip}></span>
  """
end
```

**Activity Section with Special Neovim Handling:**
```elixir
def activity_section(assigns) do
  activity = Enum.find(assigns[:presence].activities || [], &(&1["type"] not in [2, 4]))

  action = case activity do
    nil -> "Current Activity"
    %{"name" => "Neovim"} -> "Neovim, BTW"  # Special handling!
    %{"type" => 0} -> "Currently Playing"
    %{"type" => 1} -> "Currently Streaming"
    %{"type" => 3} -> "Currently Watching"
    %{"type" => 5} -> "Currently Competing"
  end

  ~H"""
  <div class="presence-section">
    <p><strong>{action}</strong></p>
    <%= cond do %>
      <% is_nil(activity) -> %>
        <p class="presence-content">N/A</p>
      <% action =~ "vim" -> %>
        <p class="presence-content">
          {Enum.join(
            Enum.reject([activity["state"], activity["details"]], &(&1 in [nil, ""])),
            ", "
          )}
        </p>
      <% true -> %>
        <p class="presence-content">{activity["name"]}</p>
    <% end %>
  </div>
  """
end
```

**Spotify Integration:**
```elixir
def listening_to_section(assigns) do
  ~H"""
  <div class="presence-section">
    <p><strong>Listening To</strong></p>
    <%= if @presence.connected? and @presence.listening_to_spotify and @presence.spotify do %>
      <p class="presence-content">{@presence.spotify["song"]} - {@presence.spotify["artist"]}</p>
    <% else %>
      <p class="presence-content">N/A</p>
    <% end %>
  </div>
  """
end
```

### Real-Time Updates

When my Discord status changes:

1. `Connection` GenServer polls Lanyard API
2. New data is stored in ETS via `Presence` GenServer
3. [PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html) broadcasts `{:presence_updated, presence}`
4. All connected LiveView processes receive the message
5. UI updates instantly without page refresh

The result is that visitors see my coding activity update in real-time as I switch between files, languages, or projects.

## The Complete Flow

Here's what happens end-to-end when I start coding:

1. **Launch Neovim in WSL**: My custom `vim()` function detects WSL and automatically starts the `socat` + `npiperelay` bridge if it's not already running
2. **cord.nvim Connects**: The plugin connects to `/tmp/discord-ipc-0` and starts sending Rich Presence updates through the bridge to Discord on Windows
3. **Discord Updates**: Windows Discord client receives the Rich Presence data and updates my status to show "Neovim" activity with file details
4. **Lanyard Polling**: My Elixir app polls Lanyard API every 15 seconds, fetching the updated Discord presence data
5. **State Update**: The `Connection` GenServer notices the presence changed and updates the ETS table via the `Presence` GenServer
6. **PubSub Broadcast**: A `{:presence_updated, presence}` message is broadcast to all subscribers
7. **LiveView Update**: My website's LiveView processes receive the message and instantly update the UI to show "Neovim, BTW" with current file details
8. **Visitor Experience**: Anyone viewing [vereis.com](https://vereis.com) sees the update happen live, without refreshing their browser

### Performance Characteristics

- **ETS Reads**: Sub-microsecond concurrent access to presence data
- **PubSub Distribution**: Phoenix PubSub efficiently broadcasts to multiple LiveView processes
- **API Polling**: 15-second intervals balance freshness with API usage
- **WSL Bridge**: Negligible overhead, runs only when needed

The system is designed to handle multiple concurrent website visitors while keeping API usage reasonable and providing sub-second UI updates.

## Lessons Learned & Future Plans

### What Works Really Well

**Layered Architecture**: Each layer has a clear responsibility and can be developed/debugged independently.

The WSL bridge, Lanyard integration, and LiveView display are completely decoupled.

**Declarative Configuration**: Everything is managed through Nix.

When I rebuild my system, the entire presence pipeline "just works" without manual setup.

**Real-Time UX**: The LiveView integration feels incredibly responsive.

Visitors often comment on seeing my status change as we chat.

### Gotchas I Discovered

**Socket Cleanup**: The bridge needs to clean up `/tmp/discord-ipc-0` on restarts, or `socat` fails to create the socket.

**Discord Dependency**: The whole system only works when Discord is running on the Windows host.

If Discord is closed, the Rich Presence updates silently fail.

**Process Management**: I removed the vim/nvim aliases because they interfered with the wrapper function.

Now I have to remember to use `vim` instead of `nvim` to get the bridge.

**Polling Frequency**: 15 seconds feels responsive but could be faster.

The tradeoff is API usage - Lanyard doesn't publish rate limits, so I err on the side of caution.

### Future Improvements

**WebSocket Connection**: Switch from HTTP polling to WebSocket for lower latency and more efficient API usage.

The [Lanyard WebSocket endpoint](https://github.com/Phineas/lanyard#websocket-api) provides real-time updates.

**Mobile Optimization**: The presence UI could be more mobile-friendly, perhaps with a collapsible sidebar.

**More Activity Types**: Currently I only handle Neovim specially, but I could add custom handling for other development tools, games, or streaming software.

**Bridge Reliability**: Add health checking and automatic restart for the WSL bridge in case it crashes.

### Why This Approach?

The alternative solutions I considered:

- **Run Discord in WSL**: Possible with [X11 forwarding](https://docs.microsoft.com/en-us/windows/wsl/tutorials/gui-apps), but heavy and defeats the purpose of using Windows Discord
- **Native Linux**: Switch to native Linux entirely, but I switch operating systems frequently, so wanted stuff to transparently work regardless of my host OS

This solution keeps Discord where it works best (Windows, in my honest opinion) while seamlessly integrating with my WSL development environment and making the whole thing visible to website visitors.

It's a testament to how powerful composable systems can be when you combine the right tools: Nix for reproducibility and dependency management, WSL bridges, robust Elixir GenServers, and reactive Phoenix LiveView all working together to solve a problem that initially seemed simple but turned out to have fascinating depth.
