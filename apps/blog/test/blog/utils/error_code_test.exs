defmodule Blog.Utils.ErrorCodeTest do
  use ExUnit.Case, async: true

  alias Blog.Utils.ErrorCode

  describe "generate/1" do
    test "generates consistent error codes for the same input" do
      assert ErrorCode.generate(nil) == ErrorCode.generate(nil)
      assert ErrorCode.generate(:test) == ErrorCode.generate(:test)
      assert ErrorCode.generate({:error, :not_found}) == ErrorCode.generate({:error, :not_found})
    end

    test "generates different error codes for different inputs" do
      code1 = ErrorCode.generate(nil)
      code2 = ErrorCode.generate(:test)
      code3 = ErrorCode.generate({:error, :not_found})

      assert code1 != code2
      assert code2 != code3
      assert code1 != code3
    end

    test "generates error codes in Windows format XX : XXXX : XXXXXXXX" do
      code = ErrorCode.generate(nil)
      assert String.match?(code, ~r/^[0-9A-F]{2} : [0-9A-F]{4} : [0-9A-F]{8}$/)
    end

    test "works with various Elixir terms" do
      terms = [
        nil,
        :atom,
        "string",
        123,
        12.34,
        [1, 2, 3],
        %{key: "value"},
        {:ok, "result"},
        {:error, :not_found},
        %Ecto.Changeset{},
        {1, 2, 3, 4}
      ]

      for term <- terms do
        code = ErrorCode.generate(term)
        assert is_binary(code)
        assert String.match?(code, ~r/^[0-9A-F]{2} : [0-9A-F]{4} : [0-9A-F]{8}$/)
      end
    end

    test "generates deterministic codes across multiple calls" do
      input = {:error, :database_connection_failed}

      codes = for _ <- 1..100, do: ErrorCode.generate(input)

      assert codes |> Enum.uniq() |> length() == 1
    end

    test "generates uppercase hexadecimal codes" do
      code = ErrorCode.generate(nil)

      # Split into parts
      [part1, part2, part3] = String.split(code, " : ")

      # Verify each part is uppercase hex
      assert String.match?(part1, ~r/^[0-9A-F]+$/)
      assert String.match?(part2, ~r/^[0-9A-F]+$/)
      assert String.match?(part3, ~r/^[0-9A-F]+$/)

      # Verify lengths
      assert String.length(part1) == 2
      assert String.length(part2) == 4
      assert String.length(part3) == 8
    end
  end
end
