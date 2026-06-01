defmodule ConvertToHex.CLI do
  @moduledoc false

  @usage """
  Usage: convert_to_hex <input> <output.svg> [--tile-size N]

  Options:
    --tile-size N   Edge length in px of each generated tile (default: 110)
    -h, --help      Show this help
  """

  def main(argv) do
    {opts, positional, invalid} =
      OptionParser.parse(argv,
        strict: [tile_size: :integer, help: :boolean],
        aliases: [h: :help]
      )

    cond do
      opts[:help] ->
        out(@usage)
        :ok

      invalid != [] ->
        err("Unknown option(s): #{inspect(invalid)}\n\n" <> @usage)
        System.halt(2)

      length(positional) != 2 ->
        err(@usage)
        System.halt(2)

      true ->
        [input, output] = positional
        run(input, output, opts)
    end
  end

  defp run(input, output, opts) do
    convert_opts =
      case Keyword.fetch(opts, :tile_size) do
        {:ok, n} -> [tile_size: n]
        :error -> []
      end

    out("Reading:  #{input}\n")
    out("Writing:  #{output}\n")

    started = System.monotonic_time(:millisecond)

    {:ok, %{width: w, height: h, unique_colors: u}} =
      ConvertToHex.convert(input, output, convert_opts)

    elapsed = System.monotonic_time(:millisecond) - started

    out("Done in #{elapsed}ms — #{w}×#{h} tiles, #{u} unique colors\n")
  end

  defp out(msg), do: IO.write(:stdio, msg)
  defp err(msg), do: IO.write(:standard_error, msg)
end
