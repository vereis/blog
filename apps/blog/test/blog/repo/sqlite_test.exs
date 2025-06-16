defmodule Blog.Repo.SQLiteTest do
  use Blog.DataCase

  alias Blog.Repo.SQLite

  describe "connection" do
    test "can execute basic query" do
      result = SQLite.query("SELECT 1", [])
      assert {:ok, %Exqlite.Result{rows: [[1]]}} = result
    end
  end
end
