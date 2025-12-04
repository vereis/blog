defmodule Blog.Resource do
  @moduledoc """
  Behaviour and macro for importable blog resources from markdown files.

  Implementing modules must provide:
  - `handle_import/1` callback to parse a resource and return attrs map(s) or `{:error, reason}`
    These attrs will be passed to the provided import function for upserting.

  Implementing modules may provide:
  - `pubsub_topic/0` callback to specify a custom PubSub topic for reload

  Implementing modules get:
  - `import/0` function to import all valid resources from the source directory.

  Options:
  - `:source_dir` (required) - Directory containing resource files
  - `:import` (required) - Function reference to upsert function (e.g., `&Context.upsert_entity/1`)
                           This function should accept attrs map and return `{:ok, entity}` or `{:error, changeset}`
  """

  defstruct [:source, :path, :content, :filename, :extension]

  @type t :: %__MODULE__{
          source: Path.t(),
          path: Path.t(),
          content: binary(),
          filename: String.t(),
          extension: String.t()
        }

  @callback source() :: Path.t()
  @callback handle_import(resource :: t()) :: map() | [map()] | {:error, term()}
  @callback import() :: {:ok, [term()]} | {:error, term()}
  @callback pubsub_topic() :: String.t()
  @optional_callbacks pubsub_topic: 0

  defmacro __using__(opts) do
    source_dir = Keyword.fetch!(opts, :source_dir)
    import_fn = Keyword.fetch!(opts, :import)
    preprocess_fn = Keyword.get(opts, :preprocess, & &1)

    quote do
      @behaviour unquote(__MODULE__)

      require Logger

      @impl unquote(__MODULE__)
      def source do
        case Blog.env() do
          :test ->
            Path.join([File.cwd!(), "test/fixtures", unquote(source_dir)])

          :dev ->
            Path.join(File.cwd!(), unquote(source_dir))

          _other ->
            :blog
            |> :code.priv_dir()
            |> Path.join(unquote(source_dir) |> Path.split() |> List.last())
        end
      end

      @impl unquote(__MODULE__)
      def import do
        read_and_parse = fn filename ->
          source_dir = source()
          path = Path.join(source_dir, filename)
          content = File.read!(path)

          resource = %unquote(__MODULE__){
            source: source_dir,
            path: path,
            content: content,
            filename: filename,
            extension: Path.extname(filename)
          }

          handle_import(resource)
        end

        {successes, errors} =
          source()
          |> File.ls!()
          |> Task.async_stream(read_and_parse, timeout: :infinity)
          |> Stream.flat_map(fn {:ok, res} -> List.wrap(res) end)
          |> Stream.map(fn attrs -> unquote(preprocess_fn).(attrs) end)
          |> Stream.map(unquote(import_fn))
          |> Enum.split_with(&match?({:ok, _res}, &1))

        if errors != [] do
          Logger.error("Invalid imports detected for #{inspect(__MODULE__)}, records skipped:")

          for {:error, error} <- errors do
            Logger.error(inspect(error))
          end
        end

        topic = pubsub_topic()
        imported = Enum.map(successes, fn {:ok, res} -> res end)

        for {:ok, resource} <- imported do
          message = {:resource_reload, __MODULE__, resource.id}
          Phoenix.PubSub.broadcast(Blog.PubSub, topic, message)
        end

        {:ok, imported}
      end

      @impl unquote(__MODULE__)
      def pubsub_topic do
        __MODULE__
        |> Module.split()
        |> List.last()
        |> String.downcase()
        |> Kernel.<>(":reload")
      end

      defoverridable source: 0, import: 0, pubsub_topic: 0
    end
  end
end
