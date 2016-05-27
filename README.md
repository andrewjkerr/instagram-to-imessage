# instagram-to-imessage

A Ruby script to send images of a certain Instagram tag via iMessage.

## setup

Make sure you have Ruby 2.3.1 installed before doing the following!

1. `git clone https://github.com/andrewjkerr/instatags.git && cd instatags`
2. `bundle install`
3. `mv config/application.yml.sample config/application.yml`
4. Put your Instagram client ID and Apple ID into the `config/application.yml`

## usage

`ruby download_and_send_images.rb [tag] [number_of_images] [target_phone_number]`

## example

`ruby download_and_send_images.rb corgi 1 8135555555`

![](https://i.imgur.com/ekGBXDq.jpg)

## contributing

If you find and want to fix an issue or something, feel free to fork, code, and submit a PR.
