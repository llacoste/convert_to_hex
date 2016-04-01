require 'RMagick'
include Magick

canvas = Magick::Image.new(110, 110){self.background_color = 'white'}
draw = Magick::Draw.new
draw.pointsize(41)
draw.font_weight = BoldWeight
draw.fill = "#ABABAB"
draw.font = File.expand_path('Anonymous.ttf')
# draw.gravity = CenterGravity
draw.text( 5,39, "0".center(0))
draw.text(43,39, "0".center(0))
draw.text(80,39, "0".center(0))

draw.text( 5,72, "2".center(0))
draw.text(43,72, "F".center(0))
draw.text(80,72, "3".center(0))

draw.text(5 ,105, "8".center(0))
draw.text(43,105, "D".center(0))
draw.text(80,105, "B".center(0))

draw.draw(canvas)
canvas.write('tst.png')
