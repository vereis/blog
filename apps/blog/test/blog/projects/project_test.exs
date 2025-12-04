defmodule Blog.Projects.ProjectTest do
  use Blog.DataCase, async: false

  alias Blog.Projects.Project

  describe "changeset/2 - validation" do
    test "validates required fields" do
      changeset = Project.changeset(%Project{}, %{})

      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert %{url: ["can't be blank"]} = errors_on(changeset)
      assert %{description: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid project attributes" do
      changeset =
        Project.changeset(%Project{}, %{
          name: "Cool Elixir Library",
          url: "https://github.com/vereis/cool_library",
          description: "A really cool library that does cool things"
        })

      assert changeset.valid?
    end

    test "enforces unique name constraint" do
      attrs = %{
        name: "Unique Project",
        url: "https://example.com",
        description: "Description"
      }

      {:ok, _project} = %Project{} |> Project.changeset(attrs) |> Repo.insert()

      assert {:error, changeset} = %Project{} |> Project.changeset(attrs) |> Repo.insert()
      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end
  end
end
