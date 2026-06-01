defmodule ConvertToHex do
  @moduledoc """
  Render an image as a mosaic where every source pixel becomes a tile
  displaying that pixel's `#RRGGBB` code in its own color.

  Output is SVG, written incrementally to disk so memory stays bounded
  regardless of source image size.
  """

  alias ConvertToHex.{Pixels, SVG}

  @default_tile_size 110

  @type opts :: [tile_size: pos_integer()]

  @doc """
  Convert `input_path` and stream the resulting SVG to `output_path`.

  Returns `{:ok, %{width: w, height: h, unique_colors: n}}` on success.
  """
  @spec convert(Path.t(), Path.t(), opts()) ::
          {:ok, %{width: pos_integer(), height: pos_integer(), unique_colors: non_neg_integer()}}
  def convert(input_path, output_path, opts \\ []) do
    tile_size = Keyword.get(opts, :tile_size, @default_tile_size)
    {width, height, rows} = Pixels.read!(input_path)

    File.mkdir_p!(Path.dirname(output_path))

    {unique_count, _cache} =
      File.open!(output_path, [:write, :utf8], fn file ->
        IO.write(file, SVG.header(width, height, tile_size))

        result =
          Enum.reduce(rows, {0, %{}}, fn {y, pixels}, {count, cache} ->
            Enum.reduce(Enum.with_index(pixels), {count, cache}, fn {pixel, x}, {c, cc} ->
              hex = SVG.rgb_to_hex(pixel)
              {fragment, cc2, c2} = fetch_fragment(cc, hex, x, y, tile_size, c)
              IO.write(file, fragment)
              {c2, cc2}
            end)
          end)

        IO.write(file, SVG.footer())
        result
      end)

    {:ok, %{width: width, height: height, unique_colors: unique_count}}
  end

  defp fetch_fragment(cache, hex, x, y, tile_size, count) do
    case Map.fetch(cache, hex) do
      {:ok, template} ->
        {place(template, x, y, tile_size), cache, count}

      :error ->
        template = SVG.cell(hex, 0, 0, tile_size)
        {place(template, x, y, tile_size), Map.put(cache, hex, template), count + 1}
    end
  end

  defp place(template, x, y, tile_size) do
    String.replace(template, "translate(0,0)", "translate(#{x * tile_size},#{y * tile_size})")
  end
end
