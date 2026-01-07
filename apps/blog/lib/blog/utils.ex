defmodule Blog.Utils do
  @moduledoc """
  General utility functions used throughout the Blog application.
  """

  @doc """
  Identity function that returns its argument unchanged.
  """
  @spec identity(term()) :: term()
  def identity(x), do: x
end
