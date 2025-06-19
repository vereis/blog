defmodule Blog.Lanyard.Supervisor do
  @moduledoc """
  Supervisor for Lanyard integration processes.
  """
  use Supervisor

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      Blog.Lanyard.Connection
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
