defmodule ConvertToHex.SVG do
  @moduledoc false

  @font_path Path.expand("../../priv/Anonymous.ttf", __DIR__)
  @external_resource @font_path
  @font_base64 @font_path |> File.read!() |> Base.encode64()

  # Each tile is a 3×3 grid of single characters, exactly like the original
  # Ruby script: the 6 hex digits are prefixed with "000" so they fill nine
  # cells, row-major: row 1 = "000", row 2 = first three of RRGGBB, row 3 =
  # last three. The 9 (x_fraction, y_fraction) anchor points are precomputed
  # so cell_inner/2 indexes them in O(1) per character.
  @positions {
    {1 / 6, 0.355},
    {1 / 2, 0.355},
    {5 / 6, 0.355},
    {1 / 6, 0.655},
    {1 / 2, 0.655},
    {5 / 6, 0.655},
    {1 / 6, 0.955},
    {1 / 2, 0.955},
    {5 / 6, 0.955}
  }

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
  Build the position-independent inner content of a tile for `hex` — a
  `<rect>` background and a `<text>` containing nine `<tspan>`s laid out in
  the 3×3 grid. The caller wraps this in a `<g transform="translate(...)">`
  to place it (see `wrap/4`); separating the two lets the inner content be
  cached per unique color without baking position into the cached string.

  `hex` must be `#RRGGBB` — the binary pattern in the head enforces this.
  """
  def cell_inner(
        <<"#", rr::binary-size(2), gg::binary-size(2), bb::binary-size(2)>> = hex,
        tile_size
      ) do
    font_size = round(tile_size * 0.32)
    chars = "000" <> rr <> gg <> bb

    tspans =
      for idx <- 0..8, into: "" do
        ch = binary_part(chars, idx, 1)
        {fx, fy} = elem(@positions, idx)
        x = Float.round(tile_size * fx, 2)
        y = Float.round(tile_size * fy, 2)
        ~s|<tspan x="#{x}" y="#{y}">#{ch}</tspan>|
      end

    ~s|<rect width="#{tile_size}" height="#{tile_size}" fill="white"/><text fill="#{hex}" font-size="#{font_size}" text-anchor="middle">#{tspans}</text>|
  end

  @doc """
  Wrap a cached `cell_inner` in a `<g transform="translate(...)">` at the
  given tile coordinates. Returns iodata so the caller can stream-write
  without building intermediate binaries.
  """
  def wrap(inner, tile_x, tile_y, tile_size) do
    [
      ~s|<g transform="translate(#{tile_x * tile_size},#{tile_y * tile_size})">|,
      inner,
      "</g>\n"
    ]
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
