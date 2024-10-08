defmodule Blog do
  @moduledoc """
  Blog keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @spec priv_dir :: Path.t()
  def priv_dir do
    :code.priv_dir(:blog)
  end
end
