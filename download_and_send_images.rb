require 'asciiart'
require 'figaro'
require 'httparty'

def figaro_init
  Figaro.application = Figaro::Application.new(environment: 'production', path: 'config/application.yml')
  Figaro.load
  Figaro.require_keys('INSTAGRAM_CLIENT_ID')
end

def process_args
  if ARGV.size != 3
    puts "Incorrect usage!"
    puts "Please run the script followed by a tag, how many images you'd like to display, and the target phone number."
    puts "For example, to display 10 corgi images, use `ruby fetch_imgs.rb corgi 10 8135555555`"
    exit
  end

  tag = ARGV[0]
  max_image_count = ARGV[1].to_i
  target_phone_number = ARGV[2]
  [tag, max_image_count, target_phone_number]
end

def download_and_send_images(tag, max_image_count, target_phone_number)
  # Initial URL
  url = "https://api.instagram.com/v1/tags/#{tag}/media/recent?client_id=#{ENV['INSTAGRAM_CLIENT_ID']}"
  image_count = 0

  # We run out of images if we don't get a next_url returned
  until url.nil?
    instagram_response = HTTParty.get(url)
    url, data = process_response(instagram_response)
    image_count = process_images(data, image_count, max_image_count, target_phone_number)

    # Check if we've reached out image count!
    return puts "Image count reached! :)" if image_count >= max_image_count
  end

  puts "Ran out of images to display. :("
end

# Grab the next_url and the data from the response
def process_response(response)
  instagram_hash = JSON.parse(response.body)
  next_url = instagram_hash.dig('pagination', 'next_url')
  data = instagram_hash.dig('data')
  [next_url, data]
end

# Process the image array
def process_images(data, image_count, max_image_count, target_phone_number)
  data.each do |image|
    return image_count if image_count >= max_image_count
    download_and_send_image(image, target_phone_number)
    image_count += 1
  end
  image_count
end

# Download the image
def download_and_send_image(image, target_phone_number)
  image_url = image['images']['standard_resolution']['url']
  image_id = image['id']
  image_path = "imgs/#{image_id}.jpg"

  File.open(image_path, 'wb') do |f|
    f.binmode
    # Party hard 🎉
    f.write HTTParty.get(image_url).parsed_response
    f.close
  end

  send_image(image_path, target_phone_number)
end

def send_image(image_path, target_phone_number)
  absolute_image_path = "#{Dir.pwd}/#{image_path}"

  osascript <<-END
    tell application "Messages"
      set imageAttachment to POSIX file "#{absolute_image_path}"
      send imageAttachment to buddy "#{target_phone_number}" of service "E:#{ENV['APPLE_ID']}"
    end tell
  END
end

def osascript(script)
  system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
end

# Main script!
figaro_init
tag, max_image_count, target_phone_number = process_args
download_and_send_images(tag, max_image_count, target_phone_number)
