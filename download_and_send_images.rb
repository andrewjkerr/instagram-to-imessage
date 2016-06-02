require 'asciiart'
require 'figaro'
require 'httparty'

def figaro_init
  Figaro.application = Figaro::Application.new(environment: 'production', path: 'config/application.yml')
  Figaro.load
  Figaro.require_keys('TUMBLR_CONSUMER_KEY')
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
  url = "https://api.tumblr.com/v2/tagged?tag=#{tag}&api_key=#{ENV['TUMBLR_CONSUMER_KEY']}"
  image_count = 0

  until url.nil?
    tumblr_response = HTTParty.get(url)
    data = process_response(tumblr_response)
    return if data.size == 0

    url = determine_pagination(data.last, tag)
    image_count = process_posts(data, image_count, max_image_count, target_phone_number)

    # Check if we've reached out image count!
    return puts "Image count reached! :)" if image_count >= max_image_count
  end

  puts "Ran out of images to display. :("
end

# Grab the next_url and the data from the response
def process_response(response)
  tumblr_hash = JSON.parse(response.body)
  tumblr_hash.dig('response')
end

def determine_pagination(post, tag)
  timestamp = post.dig("timestamp")
  return nil if timestamp.nil?

  "https://api.tumblr.com/v2/tagged?tag=#{tag}&before=timestamp&api_key=#{ENV['TUMBLR_CONSUMER_KEY']}"
end

# Process the image array
def process_posts(data, image_count, max_image_count, target_phone_number)
  data.each do |post|
    return image_count if image_count >= max_image_count
    next unless post["type"] == "photo"

    send_status = download_and_send_image(post, target_phone_number)
    image_count += 1 if send_status
  end
  image_count
end

# Download the image
def download_and_send_image(post, target_phone_number)
  tumblr_url = post['post_url']
  image_url = post['photos'].first['original_size']['url']
  post_id = post['id']
  image_path = "imgs/#{post_id}.jpg"

  File.open(image_path, 'wb') do |f|
    f.binmode
    # Party hard 🎉
    f.write HTTParty.get(image_url).parsed_response
    f.close
  end

  verified = verify_image(tumblr_url)
  return false unless verified

  send_image(image_path, target_phone_number)
end

def verify_image(tumblr_url)
  puts "Send this image? Y/n: #{tumblr_url}"
  input = STDIN.gets.chomp.downcase

  if input == 'y'
    true
  else
    false
  end
end

def send_image(image_path, target_phone_number)
  absolute_image_path = "#{Dir.pwd}/#{image_path}"

  osascript <<-END
    tell application "Messages"
      set imageAttachment to POSIX file "#{absolute_image_path}"
      send imageAttachment to buddy "#{target_phone_number}" of service "E:#{ENV['APPLE_ID']}"
    end tell
  END

  puts "Image sent!"
  true
end

def osascript(script)
  system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
end

# Main script!
figaro_init
tag, max_image_count, target_phone_number = process_args
download_and_send_images(tag, max_image_count, target_phone_number)
