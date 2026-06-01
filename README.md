# convert_to_hex

Render an image as a mosaic where every source pixel becomes a tile
displaying that pixel's `#RRGGBB` code in its own color. Output is SVG,
written incrementally to disk and bundled with the font so the file is
fully portable.

| Input | Output preview |
| --- | --- |
| ![face input](images/face.png) | ![face output](images/face-preview.jpg) |
| ![mine input](images/mine.jpeg) | ![mine output](images/mine-preview.jpg) |

The `*-preview.jpg` files are rasterizations of the SVG output for
display purposes. The full-quality SVG for `face` lives at
[`images/face.svg`](images/face.svg). The `mine` SVG is too large to
commit (~36 MB at full resolution) — regenerate it with
`just convert images/mine.jpeg tmp/mine.svg`. The `mine` preview shown
above is rendered from a downsampled copy of the input so the SVG was
small enough to rasterize quickly.

Each tile is a 3×3 grid of the pixel's hex code padded with zeros to nine
characters (`000RRGGBB`) — matching the original Ruby rendering.

Originally a 2013-era Ruby script using RMagick — the Ruby version lives
in git history. This is the Elixir rewrite, using libvips for I/O and a
hand-rolled SVG writer.

## Usage

### Via the published container

```sh
docker pull ghcr.io/llacoste/convert-to-hex:latest

docker run --rm -v "$(pwd):/work" \
  ghcr.io/llacoste/convert-to-hex:latest \
  input.png output.svg --tile-size 110
```

### Via `just` (local Docker build)

```sh
just convert input.png output.svg --tile-size 110
```

### Flags

| Flag | Default | Meaning |
| --- | --- | --- |
| `--tile-size N` | `110` | Edge length in px of each generated tile. |
| `-h`, `--help` | | Show help. |

## How it works

1. Open the image with [`image`](https://hex.pm/packages/image) (libvips).
2. Normalize to sRGB and flatten any alpha channel.
3. Read the raw pixel binary and walk it row-by-row as a `Stream`.
4. For each pixel, emit one `<g>` containing a white `<rect>` and a `<text>`
   with three `<tspan>`s (RR / GG / BB), filled in the pixel's own color.
5. Memoize the rendered fragment per unique hex string — photographs
   typically reuse colors heavily, so most tiles are template substitutions
   rather than fresh string builds.
6. Stream the result to disk as it's generated. Memory stays bounded
   regardless of source image size.

JetBrains Mono Bold (subset to `#0-9A-F`, the only glyphs we render) is
embedded as a base64 `@font-face` in the SVG's `<defs>`, so the output
renders identically in browsers, vector editors, and rasterizers without
needing the font installed. License: SIL Open Font License 1.1
([priv/LICENSE-JetBrainsMono.txt](priv/LICENSE-JetBrainsMono.txt)).

## Development

```sh
just test           # ExUnit suite inside the container
just format-check   # mix format --check-formatted
just compile        # warnings-as-errors compile
just shell          # interactive shell in the build container

just test-local     # tests without Docker (needs Elixir 1.18 + libvips)
just build-local input.png output.svg
```

## Releases

Versioned per [semver](https://semver.org/); `@version` in
[`mix.exs`](mix.exs) is the source of truth. To cut a release, bump that
constant and merge to `master` — the Deploy stage reads it, publishes
`ghcr.io/llacoste/convert-to-hex:v<version>` (plus `:latest`), and cuts
a matching GitHub Release. Merges without a version bump no-op the
publish steps. See
[Releases](https://github.com/llacoste/convert_to_hex/releases) for the
list.
