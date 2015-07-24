require 'rmagick'
require 'zlib'

class Initials
  HEX_COLORS = ['624CD1', 'AF4DD1', 'A169B4', 'D12683', 'DE66A9', '272A32', 'C62344', 'CE556E', 'D92224', 'BA4F50', 'DD601B', 'E5C62C', 'B2DA43', 'B2DA43', '7C9763', '659778', '43C5B5', '3B9BC4', '5A91A8', '97CFE6', '177EDE', '3F6688', '4C5C6B', '3B48AC', '8A90CA', '727590', 'CDCDCD', 'ACACAC', '7C7C7C', '535353', '333333', '61604C', '8A8972', 'AEAD9C', 'D5D5CC', '7C6C9']
  DEC_COLORS = HEX_COLORS.map do |color|
    color.scan(/../).map{|n|n.to_i(16) * 256}
  end

  def call(env)
    request = Rack::Request.new(env)
    if match = request.path.match(/^\/([\d]+)\/([a-f0-9]+)\/([a-z0-9]{1,2})\.png$/i)
      size = (match[1] || 100).to_i
      size = 1024 if size > 1024
      size = 2 if size < 2
      initials = match[3].upcase
      if match[2] =~ /^[0-9a-f]{6}$/i
        color = match[2].scan(/../).map{|n|n.to_i(16) * 256}
      else
        color = DEC_COLORS[Zlib.crc32(match[2]) % DEC_COLORS.size]
      end

      canvas = Magick::Image.new(size,size) do
        self.background_color = Magick::Pixel.new(*color)
      end

      text = Magick::Draw.new
      text.annotate(canvas, 0,0,0,0, initials) do
        text.gravity = Magick::CenterGravity
        self.font = "aTechSansRegular.ttf"
        self.pointsize = size / 2
        self.fill = "White"
      end

      data = canvas.to_blob do
        self.format = "png"
      end

      [200, {"conetent-type" => "image/png"}, [data]]
    else
      [404, {"conetent-type" => "text/plain"}, ["Invalid request"]]
    end
  rescue
    [500, {"conetent-type" => "text/plain"}, ["Something has gone wrong. Sorry :("]]
  end
end
