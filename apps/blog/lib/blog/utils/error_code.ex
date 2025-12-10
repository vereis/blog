defmodule Blog.Utils.ErrorCode do
  @moduledoc """
  Utilities for generating Windows-style error codes from Elixir terms.
  """

  @doc """
  Generates a deterministic Windows-style error code from any Elixir term.

  Uses `:erlang.phash2/2` to create a hash that is then formatted as a
  Windows error code in the format: `XX : XXXX : XXXXXXXX`

  ## Examples

      iex> Blog.Utils.ErrorCode.generate(nil)
      "72 : 9772 : 00000007"

      iex> Blog.Utils.ErrorCode.generate({:error, :not_found})
      "A6 : F8A6 : 0000000F"

  """
  @spec generate(term()) :: String.t()
  def generate(term) do
    hash = :erlang.phash2(term, 0xFFFFFFFF)

    part1 = hash |> rem(0xFF) |> Integer.to_string(16) |> String.pad_leading(2, "0")
    part2 = hash |> div(0x100) |> rem(0xFFFF) |> Integer.to_string(16) |> String.pad_leading(4, "0")
    part3 = hash |> div(0x10000) |> Integer.to_string(16) |> String.pad_leading(8, "0")

    "#{part1} : #{part2} : #{part3}"
  end
end
