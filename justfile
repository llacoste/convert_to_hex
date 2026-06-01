image := "convert-to-hex:dev"

default: build

# Build the Docker image used for everything else.
docker-build:
    docker build -t {{image}} .

# Run the conversion. Usage: just convert <input> <output> [extra args...]
# Example: just convert legacy/images/face.png tmp/face.svg --tile-size 60
convert *args: docker-build
    docker run --rm -v "$(pwd):/work" {{image}} {{args}}

# Alias kept for consistency with other repos' default recipe.
build: docker-build

# Run the ExUnit test suite inside the container.
test: docker-build
    docker run --rm -v "$(pwd):/work" --entrypoint mix {{image}} \
        test --color

# Compile-time check inside the container (warnings-as-errors).
compile: docker-build
    docker run --rm -v "$(pwd):/work" --entrypoint mix {{image}} \
        compile --warnings-as-errors

# Check formatting inside the container.
format-check: docker-build
    docker run --rm -v "$(pwd):/work" --entrypoint mix {{image}} \
        format --check-formatted

# Drop into a shell in the build container for poking around.
shell: docker-build
    docker run --rm -it -v "$(pwd):/work" --entrypoint /bin/bash {{image}}

# Remove generated SVGs and tmp/.
clean:
    rm -rf tmp/*.svg

# Remove all generated artifacts including build dirs.
clean-all: clean
    rm -rf _build deps

# Run the conversion without Docker (requires local Elixir + libvips install).
build-local *args:
    mix run -e 'ConvertToHex.CLI.main(System.argv())' -- {{args}}

# Run tests without Docker.
test-local:
    mix test
