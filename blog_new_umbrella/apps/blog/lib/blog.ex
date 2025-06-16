defmodule Blog do
  @moduledoc """
  Blog keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Returns the current Mix environment, with a fallback to :prod when Mix is not available.

  This is useful in compiled releases where Mix is not available at runtime.
  """
  @spec env() :: atom()
  def env do
    # credo:disable-for-next-line Credo.Check.Refactor.Apply
    apply(Mix, :env, [])
  rescue
    _error -> :prod
  end
end
