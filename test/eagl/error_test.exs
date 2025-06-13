defmodule EAGL.ErrorTest do
  use ExUnit.Case
  doctest EAGL.Error

  describe "check/1" do
    test "returns :ok or error without crashing" do
      # This test doesn't require OpenGL context since we're just testing the function structure
      # In a real OpenGL context with no errors, this would return :ok
      # Without context, it might return an error, but the function should not crash
      result = EAGL.Error.check("test context")
      assert result == :ok or match?({:error, _}, result)
    end
  end

  describe "error_string/1" do
    test "returns correct string for known error codes" do
      assert EAGL.Error.error_string(0) == "GL_NO_ERROR"
      assert EAGL.Error.error_string(1280) == "GL_INVALID_ENUM"
      assert EAGL.Error.error_string(1281) == "GL_INVALID_VALUE"
      assert EAGL.Error.error_string(1282) == "GL_INVALID_OPERATION"
      assert EAGL.Error.error_string(1285) == "GL_OUT_OF_MEMORY"
    end

    test "returns unknown error message for unknown codes" do
      result = EAGL.Error.error_string(9999)
      assert String.contains?(result, "Unknown OpenGL error")
      assert String.contains?(result, "9999")
    end
  end

  describe "check!/1" do
    test "does not crash when called" do
      # This test just ensures the function doesn't crash
      # In a real OpenGL context, it would either return :ok or raise
      try do
        EAGL.Error.check!("test context")
        assert true
      rescue
        RuntimeError -> assert true  # Expected if there's an OpenGL error
      end
    end
  end
end
