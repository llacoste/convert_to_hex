defmodule ConvertToHexTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  describe "convert/3" do
    test "renders a 2x2 image into a valid SVG with one cell per pixel", %{tmp_dir: tmp} do
      input = Path.join(tmp, "in.png")
      output = Path.join(tmp, "out.svg")

      # 2x2 image laid out row-major (R,G,B bytes per pixel):
      #   red    green
      #   blue   white
      binary = <<255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255>>
      :ok = write_rgb_png(binary, 2, 2, input)

      assert {:ok, %{width: 2, height: 2, unique_colors: 4}} =
               ConvertToHex.convert(input, output, tile_size: 50)

      svg = File.read!(output)

      assert svg =~ ~s(<svg )
      assert svg =~ ~s(width="100")
      assert svg =~ ~s(height="100")
      assert String.ends_with?(String.trim_trailing(svg), "</svg>")

      for hex <- ~w(#FF0000 #00FF00 #0000FF #FFFFFF) do
        assert svg =~ ~s(fill="#{hex}"), "expected tile for #{hex}"
      end
    end

    test "1x1 image produces exactly one tile with the right hex", %{tmp_dir: tmp} do
      input = Path.join(tmp, "tiny.png")
      output = Path.join(tmp, "tiny.svg")

      :ok = write_rgb_png(<<0x80, 0x40, 0xC8>>, 1, 1, input)

      assert {:ok, %{width: 1, height: 1, unique_colors: 1}} =
               ConvertToHex.convert(input, output, tile_size: 50)

      svg = File.read!(output)
      assert svg =~ ~s(fill="#8040C8")
      # One tile = one wrapping <g>.
      assert svg |> String.split("<g ") |> length() == 2
    end

    test "memoizes tiles by color — solid image reports 1 unique color", %{tmp_dir: tmp} do
      input = Path.join(tmp, "solid.png")
      output = Path.join(tmp, "solid.svg")

      pixel = <<100, 150, 200>>
      binary = String.duplicate(pixel, 25)
      :ok = write_rgb_png(binary, 5, 5, input)

      assert {:ok, %{width: 5, height: 5, unique_colors: 1}} =
               ConvertToHex.convert(input, output, tile_size: 20)
    end

    test "RGBA fully-transparent pixel flattens to white", %{tmp_dir: tmp} do
      input = Path.join(tmp, "transparent.png")
      output = Path.join(tmp, "transparent.svg")

      # 1x1 RGBA: pure red but alpha=0. After flatten onto white this
      # becomes #FFFFFF, not #FF0000. Verifies the documented
      # Pixels.read! / Image.flatten! behaviour.
      :ok = write_rgba_png(<<255, 0, 0, 0>>, 1, 1, input)

      assert {:ok, _} = ConvertToHex.convert(input, output, tile_size: 50)
      svg = File.read!(output)
      assert svg =~ ~s(fill="#FFFFFF")
      refute svg =~ ~s(fill="#FF0000")
    end
  end

  defp write_rgb_png(binary, width, height, path) do
    {:ok, image} =
      Vix.Vips.Image.new_from_binary(binary, width, height, 3, :VIPS_FORMAT_UCHAR)

    Image.write!(image, path)
    :ok
  end

  defp write_rgba_png(binary, width, height, path) do
    {:ok, image} =
      Vix.Vips.Image.new_from_binary(binary, width, height, 4, :VIPS_FORMAT_UCHAR)

    Image.write!(image, path)
    :ok
  end
end
