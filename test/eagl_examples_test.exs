defmodule EAGL.Examples.Test do
  use ExUnit.Case, async: false

  test "math example" do
    EAGL.Examples.Math.run_all_demos()
    assert true
  end

  test "simple shader example" do
    EAGL.Examples.SimpleShader.run_example()
    assert true
  end

  test "teapot example" do
    EAGL.Examples.Teapot.run_example()
    assert true
  end

end
