defmodule EAGL.Error do
  @moduledoc """
  OpenGL error checking and reporting utilities.

  Provides Wings3D-inspired error handling patterns with meaningful
  abstractions for development and debugging.

  ## Original Source

  Error handling patterns are inspired by Wings3D's `wings_gl.erl` module:
  <https://github.com/dgud/wings/blob/master/src/wings_gl.erl>

  ## Usage

      import EAGL.Error

      # Check for errors with context
      check("After buffer creation")

      # Get error descriptions
      error_string(1280)  # "GL_INVALID_ENUM"

      # Raise on error (debugging)
      check!("Critical operation")
  """

  use EAGL.Const

  @doc """
  Check for OpenGL errors and print them.
  Similar to Wings3D's check_error/2 function.

  ## Parameters
  - context: String describing the context where the error check is performed

  ## Returns
  - `:ok` if no error
  - `{:error, error_message}` if an error occurred

  ## Example
      EAGL.Error.check("After buffer creation")
      EAGL.Error.check("Shader compilation")
  """
  @spec check(String.t()) :: :ok | {:error, String.t()}
  def check(context \\ "OpenGL") do
    case :gl.getError() do
      @gl_no_error ->
        :ok
      @gl_invalid_enum ->
        error_msg = "#{context}: GL_INVALID_ENUM"
        IO.puts("OpenGL Error: #{error_msg}")
        {:error, error_msg}
      @gl_invalid_value ->
        error_msg = "#{context}: GL_INVALID_VALUE"
        IO.puts("OpenGL Error: #{error_msg}")
        {:error, error_msg}
      @gl_invalid_operation ->
        error_msg = "#{context}: GL_INVALID_OPERATION"
        IO.puts("OpenGL Error: #{error_msg}")
        {:error, error_msg}
      @gl_out_of_memory ->
        error_msg = "#{context}: GL_OUT_OF_MEMORY"
        IO.puts("OpenGL Error: #{error_msg}")
        {:error, error_msg}
      @gl_invalid_framebuffer_operation ->
        error_msg = "#{context}: GL_INVALID_FRAMEBUFFER_OPERATION"
        IO.puts("OpenGL Error: #{error_msg}")
        {:error, error_msg}
      error_code ->
        error_msg = "#{context}: Unknown OpenGL error #{error_code}"
        IO.puts("OpenGL Error: #{error_msg}")
        {:error, error_msg}
    end
  end

  @doc """
  Get a human-readable string for an OpenGL error code.
  Similar to Wings3D's error_string/1 function.
  """
  @spec error_string(integer()) :: String.t()
  def error_string(@gl_no_error), do: "GL_NO_ERROR"
  def error_string(@gl_invalid_enum), do: "GL_INVALID_ENUM"
  def error_string(@gl_invalid_value), do: "GL_INVALID_VALUE"
  def error_string(@gl_invalid_operation), do: "GL_INVALID_OPERATION"
  def error_string(@gl_stack_overflow), do: "GL_STACK_OVERFLOW"
  def error_string(@gl_stack_underflow), do: "GL_STACK_UNDERFLOW"
  def error_string(@gl_out_of_memory), do: "GL_OUT_OF_MEMORY"
  def error_string(@gl_invalid_framebuffer_operation), do: "GL_INVALID_FRAMEBUFFER_OPERATION"
  def error_string(@gl_context_lost), do: "GL_CONTEXT_LOST"
  def error_string(error_code), do: "Unknown OpenGL error: #{error_code}"

  @doc """
  Check for OpenGL errors and raise an exception if one is found.
  Useful for development and debugging.
  """
  @spec check!(String.t()) :: :ok
  def check!(context \\ "OpenGL") do
    case check(context) do
      :ok -> :ok
      {:error, message} -> raise RuntimeError, message
    end
  end
end
