#!/usr/bin/ruby
require 'rubygems'
require 'yaml'
require 'oauth'
require 'uri'

config = File.open('config/oauth.yml','r') do |f|
  YAML.load(f)
end
yammer_config = config["yammer"]
app_key = yammer_config['app_key']
app_secret = yammer_config['app_secret']

consumer = OAuth::Consumer.new(app_key, app_secret, {:site=>"https://www.yammer.com"})
request_token = consumer.get_request_token

puts "Visit: #{request_token.authorize_url} to authorize this app to post from your yammer account, then enter the authorization code it gives you. (You may need to log in with your yammer username and password.)"
print "Authorization code: "
auth_code = gets.chomp

access_token  = request_token.get_access_token(:oauth_verifier => auth_code)
puts "Success! Change the user_token and user_secret values in config/oauth.yml to the values shown below."
params = access_token.params
puts "user_token: #{params['oauth_token']}"
puts "user_secret: #{params['oauth_token_secret']}"
