require 'sinatra'
require 'json'
require 'RMagick'
include Magick

app_dir = File.dirname(__FILE__)

sizes=ENV['IMAGE_SIZES'] || '75,100,125,150,200'
ratio=ENV['IMAGE_RATIO'] || 1.0
cache=ENV['IMAGE_CACHE_DIR'] || "#{app_dir}/cache"

puts "Starting image service"
puts "ratio: #{ratio}"
puts "cache: #{cache}"

post '/image/:id' do
  if params['id'].nil?
    halt 400, 'no id provided'
  end

  if params['image'].nil?
    halt 400, 'no image provided'
  end

  File.open("#{cache}/#{params['id']}", "w") do |f|
    f.write(params[:image][:tempfile].read)
  end

  content_type :json
  { :id => params['id'] }.to_json
end

get '/image/:id' do

  if params['id'].nil?
    halt 400, 'no id provided'
  end

  width = params['w'] || 75
  height = params['h'] || (params['w'].to_i * ratio).to_i

  width = width.to_i
  height = height.to_i

  # resize if cached file doesn't exist
  if !File.exist?("#{cache}/#{params['id']}_#{width}_#{height}")
    # sanity check id existance
    if !File.exist?("#{cache}/#{params['id']}")
      halt 404, 'requested image does not exist'
    else
      img = Image::read("#{cache}/#{params['id']}").first
      thumb = img::resize_to_fill(width, height)
      thumb.write("#{cache}/#{params['id']}_#{width}_#{height}")
    end
  end
  puts "#{cache}/#{params['id']}_#{width}_#{height}"
  send_file("#{cache}/#{params['id']}_#{width}_#{height}")
end
