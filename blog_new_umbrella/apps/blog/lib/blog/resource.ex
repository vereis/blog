defmodule Blog.Resource do
  @moduledoc """
  Behaviour and generic implementation for importable blog resources.

  Defines the contract for modules that can import data from external sources
  into the blog system, and provides a generic import function that handles
  the orchestration.
  """

  @doc """
  Returns the source path where the resource files are located.
  """
  @callback source() :: Path.t()

  @doc """
  Parse a single resource file and return its attributes as a map.
  """
  @callback parse(filename :: String.t()) :: map()

  @doc """
  Import a list of parsed resource maps into the database.
  Handles the database-level operations for bulk importing.
  """
  @callback import(parsed_resources :: [map()]) :: :ok | {:error, term()}

  @doc """
  Generic import function that orchestrates the import process.

  1. Gets the source path from the callback module
  2. Lists all files in the source directory
  3. Parses each file using Task.async_stream for concurrency
  4. Passes the parsed results to the callback module's import function
  """
  @spec import(module()) :: :ok | {:error, term()}
  def import(callback_module) do
    callback_module.source()
    |> File.ls!()
    |> Task.async_stream(&callback_module.parse/1)
    |> Stream.map(fn {:ok, attrs} -> attrs end)
    |> Enum.to_list()
    |> callback_module.import()
  end
end
