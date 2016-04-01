require 'RMagick'
include Magick
require 'ruby-progressbar'

# CLI ARGS
$input      = File.expand_path(ARGV[0])
$output     = File.expand_path(ARGV[1])
$scale      = (ARGV[2].to_f || nil) rescue nil

# Pixel options
$pixel_size       = 110
$background_color = 'white'
$font             = File.expand_path('Anonymous.ttf')
$font_size        = 41


puts "READING: #{$input}"
puts "WRITING: #{$output}"
puts "SCALE: #{$scale}"

$progress = ProgressBar.create( :format => '%a %bᗧ%i %p%% %t', :progress_mark => ' ', :remainder_mark => '･', :starting_at => 0)

def rgb(r, g, b)
  "##{to_hex r}#{to_hex g}#{to_hex b}"
end
def to_hex(n)
  n.to_s(16).rjust(2, '0').upcase
end

def generate_hex_pixel(pixel_color)
  canvas = Magick::Image.new($pixel_size, $pixel_size){
    self.background_color = $background_color
  }
  draw              = Magick::Draw.new
  draw.font         = $font
  draw.font_weight  = BoldWeight
  draw.fill         = pixel_color
  draw.pointsize($font_size)


  text                 = "000#{pixel_color[1..-1]}"
  horizontal_positions = [39, 72, 105]
  vertical_positions   = [5, 43, 80]
  inc                  = 0

  horizontal_positions.each do |h_pos|
    vertical_positions.each do |v_pos|
      draw.text( v_pos, h_pos, text[inc].center(0))
      inc += 1
    end
  end

  # draw.text( 5,39, "0".center(0))
  # draw.text(43,39, "0".center(0))
  # draw.text(80,39, "0".center(0))
  #
  # draw.text( 5,72, pixel_color[1].center(0))
  # draw.text(43,72, pixel_color[2].center(0))
  # draw.text(80,72, pixel_color[3].center(0))
  #
  # draw.text( 5,105, pixel_color[4].center(0))
  # draw.text(43,105, pixel_color[5].center(0))
  # draw.text(80,105, pixel_color[6].center(0))

  draw.draw(canvas)
  canvas = canvas.rotate!(270).flip
  canvas = canvas.scale($scale) if $scale
  canvas
end

img    = ImageList.new($input)
pixels = img.get_pixels(0,0,img.columns,img.rows)

convert = ImageList.new
page    = Magick::Rectangle.new(0,0,0,0)

total_progress = 0.0
total          = (img.rows * img.columns).to_f

for i in 0..img.rows
  for j in 0..img.columns
    pixel_color = img.pixel_color(i,j)
    tmp = generate_hex_pixel(rgb((pixel_color.red / 257), (pixel_color.green / 257), (pixel_color.blue / 257)))
    convert << tmp #.scale(0.25)
    page.x = j * tmp.columns
    page.y = i * tmp.rows
    # puts page
    tmp.page = page
    if (((total_progress / total.to_f) * 100).floor <= 99)
      $progress.progress = ((total_progress / total.to_f) * 100).floor
      total_progress += 1
    else
      $progress.finish
    end
  end
end

puts 'Writing image, this could take a while...'

mosaic = convert.mosaic.rotate!(90).flop
mosaic.write($output)
exit
