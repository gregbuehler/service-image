require 'sinatra'
require 'json'
require 'RMagick'
include Magick

app_dir = File.dirname(__FILE__)

ratio=ENV['IMAGE_RATIO'] || 1.0
cache=ENV['IMAGE_CACHE_DIR'] || "#{app_dir}/cache"

post '/image/:id' do
  if params['id'].nil?
    halt 400, 'no id provided'
  end

  if params['image'].nil?
    halt 400, 'no image provided'
  end

  id = params['id'].gsub(/[0-9a-z]+/i, '')
  File.open("#{cache}/#{params['id']}", "w") do |f|
    f.write(params[:image][:tempfile].read)
  end

  content_type :json
  { :id => id }.to_json
end

get '/image/:id' do
  if params['id'].nil?
    halt 400, 'no id provided'
  end

  id = params['id'].gsub(/[0-9a-z]+/i, '')
  width = (params['w'] || 75).to_i
  height = (params['h'] || (params['w'].to_i * ratio).to_i).to_i

  if !File.exist?("#{cache}/#{id}_#{width}_#{height}")
    if !File.exist?("#{cache}/#{id}")
      halt 404, 'requested image does not exist'
    else
      img = Image::read("#{cache}/#{id}").first
      thumb = img::resize_to_fill(width, height)
      thumb.write("#{cache}/#{id}_#{width}_#{height}")
    end
  end

  send_file("#{cache}/#{id}_#{width}_#{height}")
end
