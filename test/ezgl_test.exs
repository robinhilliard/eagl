defmodule EZGL.Test do
  use ExUnit.Case, async: false

  test "simple shader example" do
    EZGL.Examples.SimpleShader.run_example()
    assert true
  end

  test "teapot example" do
    EZGL.Examples.Teapot.run_example()
    assert true
  end

end
