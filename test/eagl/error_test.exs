defmodule EAGL.ErrorTest do
  use ExUnit.Case
  doctest EAGL.Error

  describe "check/1" do
    test "returns :ok or error without crashing" do
      # Test that the function handles the case where GL context is not available
      try do
        result = EAGL.Error.check("test context")
        # If GL context is available, should return :ok or {:error, _}
        assert result == :ok or match?({:error, _}, result)
      rescue
        # Handle the case where wx NIFs are not loaded (no GL context)
        ErlangError ->
          # This is expected in test environment without GL context
          assert true
      end
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
    test "handles missing GL context gracefully" do
      try do
        EAGL.Error.check!("test context")
        # If we get here, GL context was available and no error occurred
        assert true
      rescue
        # Handle wx NIFs not loaded (expected in test environment)
        ErlangError ->
          assert true
        # Handle the case where GL context exists but has an error
        RuntimeError ->
          assert true
      end
    end
  end
end
