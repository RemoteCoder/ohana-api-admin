# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

#if Rails.env.production? && ENV['SECRET_TOKEN'].blank?
#  raise 'The SECRET_TOKEN environment variable is not set.\n
#  To generate it, run "rake secret", then set it with "heroku config:set SECRET_TOKEN=the_token_you_generated"'
#end

if Rails.env.production?
  ENV['SECRET_TOKEN'] = 'a80e1ecdcee5f9493d2a59eb4529521a08a9b2b88298fa9733db6935758258ee2d528286acf5750ef4ce4634b1382b83cb02ec634c2514d700a23b566bcc9de3'
end

Hsa::Application.config.secret_token = ENV['SECRET_TOKEN'] || '7f5df2af31826553ca56e75c2890e802165249fc528a0c343fad14c604750be43c073ec41bad68e935d64f26a878d48a379d649e4ba2f7ff87fc08826924fce3'
