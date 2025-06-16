defmodule BlogTest do
  use ExUnit.Case, async: true

  describe "env/0" do
    test "returns the current Mix environment when Mix is available" do
      # In test environment, this should return :test
      assert Blog.env() == :test
    end
  end
end
