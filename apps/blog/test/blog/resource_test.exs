defmodule Blog.ResourceTest do
  use Blog.DataCase, async: true

  # Mock implementation for testing the generic import function
  defmodule MockResource do
    @moduledoc false
    @behaviour Blog.Resource

    @impl Blog.Resource
    def source, do: "test/fixtures"

    @impl Blog.Resource
    def parse("file1.txt"), do: %{id: 1, name: "test1"}
    def parse("file2.txt"), do: %{id: 2, name: "test2"}
    def parse(filename), do: %{id: 3, name: filename}

    @impl Blog.Resource
    def import(parsed_resources) do
      # Store in process dictionary for testing
      Process.put(:imported_resources, parsed_resources)
      {:ok, parsed_resources}
    end
  end

  # Mock implementation that returns an error
  defmodule MockResourceWithError do
    @moduledoc false
    @behaviour Blog.Resource

    @impl Blog.Resource
    def source, do: "test/fixtures"

    @impl Blog.Resource
    def parse(filename), do: %{name: filename}

    @impl Blog.Resource
    def import(_parsed_resources), do: {:error, :test_error}
  end

  describe "import/1" do
    setup do
      # Clean up process dictionary
      Process.delete(:imported_resources)
      :ok
    end

    test "orchestrates the import process correctly" do
      # Create test fixture directory and files
      fixture_dir = "test/fixtures"
      File.mkdir_p!(fixture_dir)
      File.write!("#{fixture_dir}/file1.txt", "content1")
      File.write!("#{fixture_dir}/file2.txt", "content2")

      try do
        assert :ok = Blog.Resource.import(MockResource)

        # Verify the parsed resources were passed to import/1
        imported = Process.get(:imported_resources)
        assert is_list(imported)
        assert length(imported) == 2

        # Verify the files were parsed correctly
        assert %{id: 1, name: "test1"} in imported
        assert %{id: 2, name: "test2"} in imported
      after
        File.rm_rf!(fixture_dir)
      end
    end

    test "handles empty source directory" do
      fixture_dir = "test/fixtures"
      File.mkdir_p!(fixture_dir)

      try do
        assert :ok = Blog.Resource.import(MockResource)

        imported = Process.get(:imported_resources)
        assert imported == []
      after
        File.rm_rf!(fixture_dir)
      end
    end

    test "propagates errors from import callback" do
      fixture_dir = "test/fixtures"
      File.mkdir_p!(fixture_dir)
      File.write!("#{fixture_dir}/test.txt", "content")

      try do
        assert {:error, :test_error} = Blog.Resource.import(MockResourceWithError)
      after
        File.rm_rf!(fixture_dir)
      end
    end

    test "handles non-existent source directory" do
      defmodule MockResourceBadPath do
        @moduledoc false
        @behaviour Blog.Resource

        @impl Blog.Resource
        def source, do: "non/existent/path"

        @impl Blog.Resource
        def parse(_filename), do: %{}

        @impl Blog.Resource
        def import(_parsed_resources), do: :ok
      end

      assert_raise File.Error, fn ->
        Blog.Resource.import(MockResourceBadPath)
      end
    end
  end
end
