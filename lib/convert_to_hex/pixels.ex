defmodule ConvertToHex.Pixels do
  @moduledoc false

  alias Vix.Vips.Image, as: Vimage

  @type rgb :: {0..255, 0..255, 0..255}

  @spec read!(Path.t()) :: {pos_integer(), pos_integer(), Enumerable.t()}
  def read!(path) do
    image =
      path
      |> Image.open!()
      |> normalize_to_rgb!()

    width = Vimage.width(image)
    height = Vimage.height(image)
    {:ok, binary} = Vimage.write_to_binary(image)

    rows =
      Stream.unfold({binary, 0}, fn
        {_, ^height} ->
          nil

        {bin, y} ->
          row_bytes = width * 3
          <<row::binary-size(row_bytes), rest::binary>> = bin
          {{y, row_pixels(row)}, {rest, y + 1}}
      end)

    {width, height, rows}
  end

  defp normalize_to_rgb!(image) do
    image
    |> Image.flatten!()
    |> Image.to_colorspace!(:srgb)
  end

  defp row_pixels(<<>>), do: []

  defp row_pixels(<<r, g, b, rest::binary>>) do
    [{r, g, b} | row_pixels(rest)]
  end
end
