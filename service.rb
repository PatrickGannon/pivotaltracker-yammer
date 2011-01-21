require 'rubygems'
require 'sinatra'
require 'yaml'
require 'nokogiri'
require 'oauth'
require 'oauth/consumer'
require 'uri'

get '/hi' do
  "hello, chap!"
end

post '/yammer' do
  body = request.body.read
  doc = Nokogiri::XML(body)
  description_node = doc.xpath("/activity/description").first
  description = description_node ? description_node.content : nil
  story_url_node = doc.xpath("/activity/stories/story/url").first
  story_url = story_url_node ? story_url_node.content : nil

  if description !~ /\s(edited|added)\s/
    config = File.open("#{File.dirname(__FILE__)}/config/oauth.yml",'r') do |f|
      YAML.load(f)
    end
    yammer_config = config["yammer"]

    consumer = OAuth::Consumer.new(yammer_config['app_key'],
      yammer_config['app_secret'],
      {:site=>"https://www.yammer.com"})
    params = {:oauth_token => yammer_config['user_token'],
      :oauth_token_secret => yammer_config['user_secret']}
    token = OAuth::ConsumerToken.from_hash(consumer, params)
    message = "#{description}\n#{story_url}"
    token.request :post, "/api/v1/messages/?body=#{URI.escape(message)}"

    "Posted: #{description}"
  else
    "Ignored"
  end
end
