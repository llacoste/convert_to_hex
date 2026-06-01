defmodule ConvertToHex do
  @moduledoc """
  Render an image as a mosaic where every source pixel becomes a tile
  displaying that pixel's `#RRGGBB` code in its own color.

  Output is SVG, written incrementally to disk row-by-row. Memory is
  bounded by the number of *unique colors* in the source (each rendered
  tile is cached and reused), not by the source image's dimensions.
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
      File.open!(output_path, [:write, :utf8], &stream_svg(&1, rows, width, height, tile_size))

    {:ok, %{width: width, height: height, unique_colors: unique_count}}
  end

  defp stream_svg(file, rows, width, height, tile_size) do
    IO.write(file, SVG.header(width, height, tile_size))

    result =
      rows
      |> Stream.with_index()
      |> Enum.reduce({0, %{}}, &write_row(&1, &2, file, tile_size))

    IO.write(file, SVG.footer())
    result
  end

  defp write_row({pixels, y}, acc, file, tile_size) do
    pixels
    |> Stream.with_index()
    |> Enum.reduce(acc, fn {pixel, x}, {count, cache} ->
      {inner, cache, count} = lookup_or_render(cache, SVG.rgb_to_hex(pixel), tile_size, count)
      IO.write(file, SVG.wrap(inner, x, y, tile_size))
      {count, cache}
    end)
  end

  defp lookup_or_render(cache, hex, tile_size, count) do
    case Map.fetch(cache, hex) do
      {:ok, inner} -> {inner, cache, count}
      :error -> render_and_cache(cache, hex, tile_size, count)
    end
  end

  defp render_and_cache(cache, hex, tile_size, count) do
    inner = SVG.cell_inner(hex, tile_size)
    {inner, Map.put(cache, hex, inner), count + 1}
  end
end
