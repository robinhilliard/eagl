defmodule EAGL.WindowBehaviourTest do
  use ExUnit.Case, async: true

  describe "callback definitions" do
    test "defines required callbacks" do
      callbacks = EAGL.WindowBehaviour.behaviour_info(:callbacks)
      assert {:setup, 0} in callbacks
      assert {:render, 3} in callbacks
      assert {:cleanup, 1} in callbacks
    end

    test "defines optional callbacks" do
      optional = EAGL.WindowBehaviour.behaviour_info(:optional_callbacks)
      assert {:handle_event, 2} in optional
      assert {:render, 4} in optional
      assert {:setup_layout, 2} in optional
    end
  end

  describe "setup_layout/2 contract" do
    test "module without setup_layout is valid" do
      defmodule MinimalWindow do
        @behaviour EAGL.WindowBehaviour
        def setup, do: {:ok, %{}}
        def render(_w, _h, _state), do: :ok
        def cleanup(_state), do: :ok
      end

      refute function_exported?(MinimalWindow, :setup_layout, 2)
    end

    test "module with setup_layout is valid" do
      defmodule LayoutWindow do
        @behaviour EAGL.WindowBehaviour
        def setup, do: {:ok, %{}}
        def render(_w, _h, _state), do: :ok
        def cleanup(_state), do: :ok
        def setup_layout(_frame, _gl_canvas), do: :mock_sizer
      end

      assert function_exported?(LayoutWindow, :setup_layout, 2)
    end
  end
end
