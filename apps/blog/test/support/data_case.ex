defmodule Blog.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Blog.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Mimic

      import Blog.DataCase
      import Blog.Factory
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias Blog.Repo.Postgres, as: Repo
    end
  end

  setup tags do
    Blog.DataCase.setup_sandbox(tags)

    Mimic.stub(Vix.Vips.Image, :new_from_file, fn _file ->
      {:ok, %Vix.Vips.Image{}}
    end)

    Mimic.stub(Vix.Vips.Image, :write_to_buffer, fn _image, _format, _opts ->
      # Return a dummy binary for testing
      {:ok, <<0>>}
    end)

    Mimic.stub(Vix.Vips.Image, :width, fn _image ->
      1
    end)

    Mimic.stub(Vix.Vips.Image, :height, fn _image ->
      1
    end)

    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    postgres_pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(Blog.Repo.Postgres, shared: not tags[:async])

    sqlite_pid =
      Ecto.Adapters.SQL.Sandbox.start_owner!(Blog.Repo.SQLite, shared: not tags[:async])

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(postgres_pid)
      Ecto.Adapters.SQL.Sandbox.stop_owner(sqlite_pid)
    end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
