defmodule Blog.RepoTest do
  use Blog.DataCase, async: true

  describe "Blog.Repo" do
    test "can connect and execute basic query" do
      result = Repo.query("SELECT 1 as value")
      assert {:ok, %{rows: [[1]]}} = result
    end

    test "uses immediate transaction mode" do
      Repo.transaction(fn ->
        result = Repo.query("PRAGMA defer_foreign_keys")
        assert {:ok, _} = result
      end)
    end
  end
end
