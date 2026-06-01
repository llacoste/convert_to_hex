defmodule ConvertToHex.SVG do
  @moduledoc false

  @font_path Path.expand("../../priv/Anonymous.ttf", __DIR__)
  @external_resource @font_path
  @font_base64 @font_path |> File.read!() |> Base.encode64()

  # Each tile is a 3×3 grid of single characters, exactly like the original
  # Ruby script: the 6 hex digits are prefixed with "000" so they fill nine
  # cells, row-major: row 1 = "000", row 2 = first three of RRGGBB, row 3 =
  # last three.
  @col_fractions [1 / 6, 1 / 2, 5 / 6]
  @row_fractions [0.355, 0.655, 0.955]

  @doc """
  Opening `<svg>` tag plus a `<defs>` block embedding the bundled Anonymous TTF
  so the output renders identically regardless of where it's opened.
  """
  def header(grid_width, grid_height, tile_size) do
    width = grid_width * tile_size
    height = grid_height * tile_size

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}" viewBox="0 0 #{width} #{height}" shape-rendering="crispEdges">
    <defs>
    <style><![CDATA[
    @font-face {
      font-family: 'AnonymousEmbedded';
      src: url('data:font/ttf;base64,#{@font_base64}') format('truetype');
      font-weight: bold;
    }
    text { font-family: 'AnonymousEmbedded', monospace; font-weight: bold; }
    ]]></style>
    </defs>
    """
  end

  def footer, do: "</svg>\n"

  @doc """
  Render a single tile at (tile_x, tile_y) for the given hex string
  (`#RRGGBB`). The hex is padded to nine characters (`"000" <> RRGGBB`) and
  laid out as a 3×3 grid of single chars — matching the original Ruby
  rendering.
  """
  def cell(hex, tile_x, tile_y, tile_size) do
    px = tile_x * tile_size
    py = tile_y * tile_size
    font_size = round(tile_size * 0.32)

    <<"#", rr::binary-size(2), gg::binary-size(2), bb::binary-size(2)>> = hex
    chars = String.graphemes("000" <> rr <> gg <> bb)

    tspans =
      chars
      |> Enum.with_index()
      |> Enum.map_join(fn {ch, idx} ->
        row = div(idx, 3)
        col = rem(idx, 3)
        x = tile_size * Enum.at(@col_fractions, col)
        y = tile_size * Enum.at(@row_fractions, row)
        ~s|<tspan x="#{x}" y="#{y}">#{ch}</tspan>|
      end)

    ~s|<g transform="translate(#{px},#{py})"><rect width="#{tile_size}" height="#{tile_size}" fill="white"/><text fill="#{hex}" font-size="#{font_size}" text-anchor="middle">#{tspans}</text></g>\n|
  end

  @doc "RGB tuple → uppercase `#RRGGBB`."
  def rgb_to_hex({r, g, b}) do
    "#" <> byte_hex(r) <> byte_hex(g) <> byte_hex(b)
  end

  defp byte_hex(n) do
    n
    |> Integer.to_string(16)
    |> String.pad_leading(2, "0")
  end
end
