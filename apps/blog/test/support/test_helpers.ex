defmodule Blog.TestHelpers do
  @moduledoc """
  Helper functions for testing asynchronous behavior and eventual consistency.
  """

  @doc """
  Polls a function until it returns a truthy value or times out.

  ## Examples

      # Wait until a post is imported
      assert eventually(fn -> Blog.Posts.list_posts() != [] end)

      # Wait with custom timeout
      assert eventually(fn -> GenServer call completes end, timeout: :timer.seconds(10))

      # Wait with custom polling interval
      assert eventually(fn -> file_exists?("path") end, 
        timeout: :timer.seconds(5), 
        interval: 50)

  ## Options

    * `:timeout` - Maximum time to wait in milliseconds (default: 5000)
    * `:interval` - Time between polls in milliseconds (default: 100)

  """
  @spec eventually(function(), keyword()) :: boolean()
  def eventually(assertion_fn, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, to_timeout(second: 5))
    interval = Keyword.get(opts, :interval, 100)
    deadline = System.monotonic_time(:millisecond) + timeout

    poll_until(assertion_fn, deadline, interval)
  end

  defp poll_until(assertion_fn, deadline, interval) do
    case assertion_fn.() do
      true ->
        true

      false ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(interval)
          poll_until(assertion_fn, deadline, interval)
        else
          false
        end

      other ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(interval)
          poll_until(assertion_fn, deadline, interval)
        else
          raise "eventually/2 expected function to return boolean, got: #{inspect(other)}"
        end
    end
  end

  @doc """
  Waits for a GenServer to process all messages in its mailbox.

  Useful for ensuring a GenServer has finished processing before making assertions.

  ## Examples

      wait_for_genserver(MyGenServer)
      state = :sys.get_state(MyGenServer)
      assert state.field == expected_value

  """
  @spec wait_for_genserver(GenServer.server()) :: :ok
  def wait_for_genserver(server) do
    _ = :sys.get_state(server)
    :ok
  end
end
