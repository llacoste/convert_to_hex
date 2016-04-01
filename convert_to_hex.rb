require 'RMagick'
include Magick
require 'ruby-progressbar'

# CLI ARGS
$input      = File.expand_path(ARGV[0])
$output     = File.expand_path(ARGV[1])
$scale      = ARGV[2] ? ARGV[2].to_f : 1

# Pixel options
$pixel_size           = 110
$background_color     = 'white'
$font                 = File.expand_path('Anonymous.ttf')
$font_size            = 41
$horizontal_positions = [39, 72, 105]
$vertical_positions   = [5, 43, 80]


puts "READING: #{$input}"
puts "WRITING: #{$output}"
puts "SCALE: #{$scale}"

# Progress tracking
$progress  = ProgressBar.create( :format => '%a %bᗧ%i %p%% %t', :progress_mark => ' ', :remainder_mark => '･', :starting_at => 0)
$ops       = 0.0
$total_ops = 0.0

# Returns hex given a pixel color object from rmagick
def rgb_to_hex(pixel_color)
  "##{to_hex (pixel_color.red / 257)}#{to_hex (pixel_color.green / 257)}#{to_hex (pixel_color.blue / 257)}"
end

# Helper method to rgb
def to_hex(n)
  n.to_s(16).rjust(2, '0').upcase
end

# Given the color of a pixel, print the pixel's text value in its own color
# onto a square canvas.
def generate_hex_pixel(pixel_color)
  canvas = Magick::Image.new($pixel_size, $pixel_size){
    self.background_color = $background_color
  }
  draw              = Magick::Draw.new
  draw.font         = $font
  draw.font_weight  = BoldWeight
  draw.fill         = pixel_color
  draw.pointsize($font_size)
  text              = "000#{pixel_color[1..-1]}"
  inc               = 0

  $horizontal_positions.each do |h_pos|
    $vertical_positions.each do |v_pos|
      draw.text( v_pos, h_pos, text[inc].center(0))
      inc += 1
    end
  end

  draw.draw(canvas)
  canvas.rotate!(270).flip.scale($scale)
end

# Manipulates the progress bar so we have an idea of where we are in the
# process.
def progress()
  percent = (($ops / $total_ops) * 100).floor
  if (percent <= 99)
    $progress.progress = percent
    $ops += 1
  else
    $progress.finish
  end
end

# Convert an image to its hex representation!
def main()
  img        = ImageList.new($input)
  convert    = ImageList.new
  page       = Magick::Rectangle.new(0,0,0,0)
  $total_ops = (img.rows * img.columns).to_f

  for i in 0..img.rows
    for j in 0..img.columns
      pixel = generate_hex_pixel(rgb_to_hex(img.pixel_color(i,j)))
      convert << pixel
      page.x     = j * pixel.columns
      page.y     = i * pixel.rows
      pixel.page = page
      progress()
    end
  end

  puts 'Writing image, this could take a while...'
  convert.mosaic.rotate!(90).flop.write($output)
end

main()
`open #{$output}`
`say 'Take a look'`
exit
