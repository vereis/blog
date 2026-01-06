defmodule Blog.Content.LinkTest do
  use Blog.DataCase, async: true

  alias Blog.Content.Link

  describe "changeset/2 - validation" do
    test "validates required fields" do
      changeset = Link.changeset(%Link{}, %{})

      refute changeset.valid?
      assert %{source_slug: ["can't be blank"]} = errors_on(changeset)
      assert %{target_slug: ["can't be blank"]} = errors_on(changeset)
      assert %{context: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid body context" do
      changeset =
        Link.changeset(%Link{}, %{
          source_slug: "essays/my-post",
          target_slug: "essays/other-post",
          context: :body
        })

      assert changeset.valid?
    end

    test "accepts valid tag context" do
      changeset =
        Link.changeset(%Link{}, %{
          source_slug: "essays/my-post",
          target_slug: "tags/elixir",
          context: :tag
        })

      assert changeset.valid?
    end

    test "accepts string context values" do
      changeset =
        Link.changeset(%Link{}, %{
          source_slug: "essays/my-post",
          target_slug: "essays/other-post",
          context: "body"
        })

      assert changeset.valid?
    end

    test "rejects invalid context values" do
      changeset =
        Link.changeset(%Link{}, %{
          source_slug: "essays/my-post",
          target_slug: "essays/other-post",
          context: :invalid
        })

      refute changeset.valid?
      assert %{context: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "composite primary key" do
    test "allows same source and target with different contexts" do
      # Insert a body link
      {:ok, _body_link} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/my-post",
          target_slug: "tags/elixir",
          context: :body
        })
        |> Repo.insert()

      # Insert a tag link with same slugs but different context
      {:ok, tag_link} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/my-post",
          target_slug: "tags/elixir",
          context: :tag
        })
        |> Repo.insert()

      assert tag_link.context == :tag
    end

    test "rejects duplicate source, target, and context combination" do
      {:ok, _link} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/my-post",
          target_slug: "essays/other-post",
          context: :body
        })
        |> Repo.insert()

      {:error, changeset} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/my-post",
          target_slug: "essays/other-post",
          context: :body
        })
        |> Repo.insert()

      assert %{source_slug: ["has already been taken"]} = errors_on(changeset)
    end

    test "allows same source with different targets" do
      {:ok, _link1} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/my-post",
          target_slug: "essays/post-a",
          context: :body
        })
        |> Repo.insert()

      {:ok, link2} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/my-post",
          target_slug: "essays/post-b",
          context: :body
        })
        |> Repo.insert()

      assert link2.target_slug == "essays/post-b"
    end
  end

  describe "query/2 - filtering" do
    setup do
      {:ok, link1} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/post-a",
          target_slug: "essays/post-b",
          context: :body
        })
        |> Repo.insert()

      {:ok, link2} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/post-a",
          target_slug: "tags/elixir",
          context: :tag
        })
        |> Repo.insert()

      {:ok, link3} =
        %Link{}
        |> Link.changeset(%{
          source_slug: "essays/post-b",
          target_slug: "essays/post-a",
          context: :body
        })
        |> Repo.insert()

      %{link1: link1, link2: link2, link3: link3}
    end

    test "filters by source_slug", %{link1: link1, link2: link2} do
      results =
        Link
        |> Link.query(source_slug: "essays/post-a")
        |> Repo.all()

      assert length(results) == 2
      result_targets = results |> Enum.map(& &1.target_slug) |> Enum.sort()
      assert result_targets == ["essays/post-b", "tags/elixir"]
      assert link1 in results
      assert link2 in results
    end

    test "filters by target_slug", %{link1: link1, link3: link3} do
      results =
        Link
        |> Link.query(target_slug: "essays/post-b")
        |> Repo.all()

      assert length(results) == 1
      assert hd(results).source_slug == "essays/post-a"
      assert link1 in results
      refute link3 in results
    end

    test "filters by context atom", %{link1: link1, link3: link3} do
      results =
        Link
        |> Link.query(context: :body)
        |> Repo.all()

      assert length(results) == 2
      assert link1 in results
      assert link3 in results
    end

    test "filters by context string", %{link2: link2} do
      results =
        Link
        |> Link.query(context: "tag")
        |> Repo.all()

      assert length(results) == 1
      assert hd(results).target_slug == "tags/elixir"
      assert link2 in results
    end

    test "combines multiple filters", %{link1: link1} do
      results =
        Link
        |> Link.query(source_slug: "essays/post-a", context: :body)
        |> Repo.all()

      assert length(results) == 1
      assert hd(results).target_slug == "essays/post-b"
      assert link1 in results
    end

    test "returns empty list when no matches" do
      results =
        Link
        |> Link.query(source_slug: "nonexistent/slug")
        |> Repo.all()

      assert results == []
    end
  end

  describe "backlinks query pattern" do
    setup do
      # Create a network of links:
      # post-a -> post-b (body)
      # post-a -> post-c (body)
      # post-b -> post-a (body) - backlink
      # post-c -> post-a (tag)  - backlink with different context

      {:ok, _} =
        %Link{}
        |> Link.changeset(%{source_slug: "essays/post-a", target_slug: "essays/post-b", context: :body})
        |> Repo.insert()

      {:ok, _} =
        %Link{}
        |> Link.changeset(%{source_slug: "essays/post-a", target_slug: "essays/post-c", context: :body})
        |> Repo.insert()

      {:ok, _} =
        %Link{}
        |> Link.changeset(%{source_slug: "essays/post-b", target_slug: "essays/post-a", context: :body})
        |> Repo.insert()

      {:ok, _} =
        %Link{}
        |> Link.changeset(%{source_slug: "essays/post-c", target_slug: "essays/post-a", context: :tag})
        |> Repo.insert()

      :ok
    end

    test "finds all backlinks to a content item" do
      backlinks =
        Link
        |> Link.query(target_slug: "essays/post-a")
        |> Repo.all()

      assert length(backlinks) == 2
      sources = backlinks |> Enum.map(& &1.source_slug) |> Enum.sort()
      assert sources == ["essays/post-b", "essays/post-c"]
    end

    test "finds backlinks by context" do
      body_backlinks =
        Link
        |> Link.query(target_slug: "essays/post-a", context: :body)
        |> Repo.all()

      assert length(body_backlinks) == 1
      assert hd(body_backlinks).source_slug == "essays/post-b"

      tag_backlinks =
        Link
        |> Link.query(target_slug: "essays/post-a", context: :tag)
        |> Repo.all()

      assert length(tag_backlinks) == 1
      assert hd(tag_backlinks).source_slug == "essays/post-c"
    end

    test "finds outbound links from a content item" do
      outbound =
        Link
        |> Link.query(source_slug: "essays/post-a")
        |> Repo.all()

      assert length(outbound) == 2
      targets = outbound |> Enum.map(& &1.target_slug) |> Enum.sort()
      assert targets == ["essays/post-b", "essays/post-c"]
    end
  end
end
