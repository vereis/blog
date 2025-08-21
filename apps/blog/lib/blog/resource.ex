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
  Parse a single resource file and return its attributes as a map or list of maps.
  """
  @callback parse(filename :: String.t()) :: map() | [map()]

  @doc """
  Import a list of parsed resource maps into the database.
  Handles the database-level operations for bulk importing.
  Returns a list of imported resources with their IDs.
  """
  @callback import(parsed_resources :: [map()]) :: {:ok, [map()]} | {:error, term()}

  @doc """
  Returns the PubSub topic for resource reload notifications.
  Defaults to the module's final segment downcased with ":reload" suffix.
  Can be overridden by implementing modules.
  """
  @callback pubsub_topic() :: String.t()

  @optional_callbacks pubsub_topic: 0

  @doc """
  Generic import function that orchestrates the import process.

  1. Gets the source path from the callback module
  2. Lists all files in the source directory
  3. Parses each file
  4. Passes the parsed results to the callback module's import function to persist
  """
  @spec import(module()) :: :ok | {:error, term()}
  def import(callback_module) do
    parsed_resources =
      callback_module.source()
      |> File.ls!()
      |> Task.async_stream(&callback_module.parse/1)
      |> Stream.flat_map(fn {:ok, attrs} -> List.wrap(attrs) end)
      |> Enum.to_list()

    case callback_module.import(parsed_resources) do
      {:ok, imported_resources} ->
        # Broadcast reload message
        topic = get_pubsub_topic(callback_module)

        # Send reload message for each imported resource
        for resource <- imported_resources do
          message = {:resource_reload, callback_module, resource.id}
          Phoenix.PubSub.broadcast(Blog.PubSub, topic, message)
        end

        :ok

      {:error, _reason} = error ->
        error
    end
  end

  defp get_pubsub_topic(callback_module) do
    if function_exported?(callback_module, :pubsub_topic, 0) do
      callback_module.pubsub_topic()
    else
      # Default: extract final module segment, downcase, and add ":reload"
      callback_module
      |> Module.split()
      |> List.last()
      |> String.downcase()
      |> Kernel.<>(":reload")
    end
  end
end
