defmodule Blog.Content do
  @moduledoc """
  Central module for importing blog content from files.

  Provides `import/1` to import all content from a path, and `import/2` to import
  specific content types. Content types implement `handle_import/1` callback.

  ## Content Types

  - `Blog.Assets.Asset` - Images and other assets
  - `Blog.Posts.Post` - Blog posts (markdown files in archived/)
  - `Blog.Projects.Project` - Projects (YAML file)

  ## Options for `use Blog.Content`

  - `:import` (required) - Function to upsert parsed content (e.g., `&Blog.Posts.upsert_post/1`)
  - `:preprocess` - Optional function to transform attrs before import
  """

  require Logger

  defstruct [:source, :path, :content, :filename, :extension]

  @type t :: %__MODULE__{
          source: Path.t(),
          path: Path.t(),
          content: binary(),
          filename: String.t(),
          extension: String.t()
        }

  @type content_type :: Blog.Assets.Asset | Blog.Posts.Post | Blog.Projects.Project

  @callback handle_import(resource :: t()) :: map() | [map()] | {:error, term()}

  @pubsub_topic "content:reload"

  @doc """
  Returns the PubSub topic for content reload broadcasts.
  """
  @spec pubsub_topic() :: String.t()
  def pubsub_topic, do: @pubsub_topic

  @doc """
  Returns the base path to the content directory.
  """
  @spec content_path() :: Path.t()
  def content_path do
    :blog
    |> Application.app_dir()
    |> Path.join("priv/content")
  end

  @doc """
  Imports all content from the given path.

  Imports assets, posts, and projects in order and broadcasts a single
  `:content_imported` message on completion.
  """
  @spec import_all(Path.t()) :: {:ok, map()} | {:error, term()}
  def import_all(path) do
    alias Blog.Assets.Asset
    alias Blog.Posts.Post
    alias Blog.Projects.Project

    with {:ok, assets} <- import_content(Asset, Path.join(path, "assets")),
         {:ok, posts} <- import_content(Post, Path.join(path, "archived")),
         {:ok, projects} <- import_content(Project, Path.join(path, "projects")) do
      Phoenix.PubSub.broadcast(Blog.PubSub, @pubsub_topic, {:content_imported})

      {:ok, %{assets: assets, posts: posts, projects: projects}}
    end
  end

  @doc """
  Imports content of a specific type from the given path.
  """
  @spec import_content(content_type(), Path.t()) :: {:ok, [struct()]} | {:error, term()}
  def import_content(module, path) do
    import_fn = module.__content_import_fn__()
    preprocess_fn = module.__content_preprocess_fn__()

    read_and_parse = fn filename ->
      file_path = Path.join(path, filename)
      content = File.read!(file_path)

      resource = %__MODULE__{
        source: path,
        path: file_path,
        content: content,
        filename: filename,
        extension: Path.extname(filename)
      }

      module.handle_import(resource)
    end

    {successes, errors} =
      path
      |> File.ls!()
      |> Enum.reject(&String.starts_with?(&1, "."))
      |> Task.async_stream(read_and_parse, timeout: :infinity)
      |> Stream.flat_map(fn {:ok, res} -> List.wrap(res) end)
      |> Stream.map(preprocess_fn)
      |> Stream.map(import_fn)
      |> Enum.split_with(&match?({:ok, _res}, &1))

    if errors != [] do
      Logger.error("Invalid imports detected for #{inspect(module)}, records skipped:")

      for {:error, error} <- errors do
        Logger.error(inspect(error))
      end
    end

    {:ok, Enum.map(successes, fn {:ok, res} -> res end)}
  end

  @doc false
  def identity(x), do: x

  defmacro __using__(opts) do
    import_fn = Keyword.fetch!(opts, :import)
    preprocess_fn = Keyword.get(opts, :preprocess, &__MODULE__.identity/1)

    quote do
      @behaviour unquote(__MODULE__)

      @doc false
      def __content_import_fn__, do: unquote(import_fn)

      @doc false
      def __content_preprocess_fn__, do: unquote(preprocess_fn)
    end
  end
end
