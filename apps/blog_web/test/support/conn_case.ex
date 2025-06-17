defmodule BlogWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use BlogWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      use BlogWeb, :verified_routes

      # Import conveniences for testing with connections
      import BlogWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn
      use Mimic

      @endpoint BlogWeb.Endpoint
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

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
