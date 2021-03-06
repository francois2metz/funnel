defmodule Funnel.PercolatorTest do
  use Funnel.TestCase, async: true

  test "percolator is alive" do
    {:ok, percolator} = Funnel.Percolator.start_link(nil)
    assert Process.alive?(percolator)
  end
end
