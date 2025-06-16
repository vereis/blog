defmodule Blog.Repo.PostgresTest do
  use Blog.DataCase

  alias Blog.Repo.Postgres

  describe "connection" do
    test "can execute basic query" do
      result = Postgres.query("SELECT 1", [])
      assert {:ok, %Postgrex.Result{rows: [[1]]}} = result
    end
  end
end
