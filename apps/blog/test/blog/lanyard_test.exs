defmodule Blog.LanyardTest do
  use Blog.DataCase, async: true

  describe "get_user_id/0" do
    test "returns configured Discord user ID" do
      # The user ID should be loaded from application config
      user_id = Blog.Lanyard.get_user_id()
      assert is_binary(user_id)
      assert String.length(user_id) > 0
    end
  end

  describe "poll_interval/0" do
    test "returns configured poll interval in milliseconds" do
      # The poll interval should be loaded from application config
      interval = Blog.Lanyard.poll_interval()
      assert is_integer(interval)
      assert interval > 0
      # Should be at least 1 second
      assert interval >= 1000
    end
  end

  describe "api_url/1" do
    test "returns base API URL when no user ID provided" do
      url = Blog.Lanyard.api_url()
      assert url == "https://api.lanyard.rest/v1/users"
    end

    test "returns base API URL when nil user ID provided" do
      url = Blog.Lanyard.api_url(nil)
      assert url == "https://api.lanyard.rest/v1/users"
    end

    test "returns API URL with user ID appended when user ID provided" do
      user_id = "123456789"
      url = Blog.Lanyard.api_url(user_id)
      assert url == "https://api.lanyard.rest/v1/users/#{user_id}"
    end

    test "integrates with get_user_id/0" do
      user_id = Blog.Lanyard.get_user_id()
      url = Blog.Lanyard.api_url(user_id)
      expected_url = "https://api.lanyard.rest/v1/users/#{user_id}"
      assert url == expected_url
    end
  end
end
