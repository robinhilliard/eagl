defmodule EAGL.Examples.Test do
  use ExUnit.Case, async: false

  test "math example" do
    EAGL.Examples.Math.run_example()
    assert true
  end

  test "teapot example" do
    EAGL.Examples.Teapot.run_example()
    assert true
  end

end
