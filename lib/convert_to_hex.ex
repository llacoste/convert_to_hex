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
      File.open!(output_path, [:write, :utf8], &stream_svg(&1, rows, width, height, tile_size))

    {:ok, %{width: width, height: height, unique_colors: unique_count}}
  end

  defp stream_svg(file, rows, width, height, tile_size) do
    IO.write(file, SVG.header(width, height, tile_size))
    result = Enum.reduce(rows, {0, %{}}, &write_row(&1, &2, file, tile_size))
    IO.write(file, SVG.footer())
    result
  end

  defp write_row({y, pixels}, acc, file, tile_size) do
    pixels
    |> Enum.with_index()
    |> Enum.reduce(acc, fn {pixel, x}, {count, cache} ->
      hex = SVG.rgb_to_hex(pixel)
      {fragment, cache, count} = fetch_fragment(cache, hex, x, y, tile_size, count)
      IO.write(file, fragment)
      {count, cache}
    end)
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
