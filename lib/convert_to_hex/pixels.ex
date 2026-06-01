defmodule ConvertToHex.Pixels do
  @moduledoc false

  alias Vix.Vips.Image, as: Vimage

  @type rgb :: {0..255, 0..255, 0..255}

  @doc """
  Open `path`, normalize to 8-bit sRGB, and return
  `{width, height, row_stream}` where `row_stream` yields one list of
  `{r, g, b}` tuples per source row.

  Images with an alpha channel are flattened onto an opaque **white**
  background before reading — semi-transparent pixels shift toward white
  proportionally to their alpha, fully-transparent pixels become
  `#FFFFFF`. White matches the per-tile background in the SVG output, so
  transparent regions visually disappear instead of producing surprising
  hex codes. libvips' own default for `flatten` is black, hence the
  explicit `background_color` here.
  """
  @spec read!(Path.t()) :: {pos_integer(), pos_integer(), Enumerable.t()}
  def read!(path) do
    image =
      path
      |> Image.open!()
      |> Image.flatten!(background_color: :white)
      |> Image.to_colorspace!(:srgb)

    width = Vimage.width(image)
    height = Vimage.height(image)
    {:ok, binary} = Vimage.write_to_binary(image)

    {width, height, stream_rows(binary, width)}
  end

  defp stream_rows(binary, width) do
    row_bytes = width * 3

    Stream.unfold(binary, fn
      <<>> ->
        nil

      bin ->
        <<row::binary-size(row_bytes), rest::binary>> = bin
        {row_pixels(row), rest}
    end)
  end

  defp row_pixels(binary) do
    for <<r, g, b <- binary>>, do: {r, g, b}
  end
end
