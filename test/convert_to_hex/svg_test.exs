defmodule ConvertToHex.SVGTest do
  use ExUnit.Case, async: true

  alias ConvertToHex.SVG

  describe "rgb_to_hex/1" do
    test "uppercase, zero-padded" do
      assert SVG.rgb_to_hex({0, 0, 0}) == "#000000"
      assert SVG.rgb_to_hex({255, 255, 255}) == "#FFFFFF"
      assert SVG.rgb_to_hex({10, 11, 12}) == "#0A0B0C"
      assert SVG.rgb_to_hex({163, 178, 193}) == "#A3B2C1"
    end
  end

  describe "header/3" do
    test "computes viewport dimensions from grid × tile size" do
      svg = SVG.header(4, 3, 110)
      assert svg =~ ~s(width="440")
      assert svg =~ ~s(height="330")
      assert svg =~ ~s(viewBox="0 0 440 330")
    end

    test "embeds the font as base64" do
      svg = SVG.header(1, 1, 10)
      assert svg =~ "data:font/ttf;base64,"
      assert svg =~ "font-family: 'AnonymousEmbedded'"
    end
  end

  describe "cell/4" do
    test "renders the 3x3 grid as 9 single-char tspans with 000-padded hex" do
      fragment = SVG.cell("#A3B2C1", 0, 0, 110)
      assert fragment =~ ~s(fill="#A3B2C1")

      # 9 tspans total
      assert fragment |> String.split("<tspan") |> length() == 10
      # All characters of "000A3B2C1" appear as single-char tspans
      for ch <- String.graphemes("000A3B2C1") do
        assert fragment =~ ">#{ch}</tspan>"
      end
    end

    test "positions the tile via translate()" do
      assert SVG.cell("#000000", 2, 3, 110) =~ "translate(220,330)"
    end
  end
end
