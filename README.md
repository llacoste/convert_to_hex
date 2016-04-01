# convert_to_hex.rb

This ruby script can take an image and create a hexadecimal representation of it.

## Requirements
- ImageMagick
  - brew install imagemagick --disable-openmp --build-from-source
- Rmagick Gem
  - [Instructions](https://stackoverflow.com/questions/11711967/cant-install-rmagick-in-mountain-lion)
- Ruby Progress Bar Gem
  - gem install 'ruby-progressbar'

## Usage
```
ruby convert_to_hex.rb <PATH_TO_INPUT_IMAGE> <PATH_TO_WRITE_PUT_IMAGE> <SCALE (0..1)>
```
