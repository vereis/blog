defmodule Blog.Resource do
  @moduledoc """
  Behaviour and macro for importable blog resources from markdown files.

  Implementing modules must provide:
  - `handle_import/1` callback to parse a resource and return a changeset or `{:error, reason}`
    These changesets will be bulk inserted into the database.

  Implementing modules may provide:
  - `pubsub_topic/0` callback to specify a custom PubSub topic for reload

  Implementing modules get:
  - `import/0` function to import all valid resources from the source directory.

  Options:
  - `:source_dir` (required) - Directory containing resource files
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
  @callback handle_import(resource :: t()) :: Ecto.Changeset.t() | {:error, term()}
  @callback import() :: {:ok, [term()]} | {:error, term()}
  @callback pubsub_topic() :: String.t()
  @optional_callbacks pubsub_topic: 0

  defmacro __using__(opts) do
    source_dir = Keyword.fetch!(opts, :source_dir)

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

        {changesets, errors} =
          source()
          |> File.ls!()
          |> Task.async_stream(read_and_parse, timeout: :infinity)
          |> Enum.split_with(&match?({:ok, %Ecto.Changeset{valid?: true}}, &1))

        if errors != [] do
          Logger.error("Errors occurred during import of #{inspect(__MODULE__)}:")

          for error <- errors do
            Logger.error(inspect(error))
          end
        end

        case changesets do
          [] ->
            {:ok, []}

          changesets ->
            valid_changesets = Enum.map(changesets, fn {:ok, changeset} -> changeset end)
            first_changeset = hd(valid_changesets)

            now = DateTime.utc_now() |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

            entries =
              Enum.map(valid_changesets, fn changeset ->
                changeset
                |> Ecto.Changeset.apply_changes()
                |> Map.from_struct()
                |> Map.drop([:id, :__meta__])
                |> Map.put(:inserted_at, now)
                |> Map.put(:updated_at, now)
              end)

            {_count, imported} =
              Blog.Repo.insert_all(
                first_changeset.data.__struct__,
                entries,
                on_conflict: {:replace_all_except, [:id, :inserted_at]},
                conflict_target: :slug,
                returning: true
              )

            topic = pubsub_topic()

            for resource <- imported do
              message = {:resource_reload, __MODULE__, resource.id}
              Phoenix.PubSub.broadcast(Blog.PubSub, topic, message)
            end

            {:ok, imported}
        end
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
