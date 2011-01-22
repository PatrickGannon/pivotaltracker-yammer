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
  project_id_node = doc.xpath("/activity/project_id").first
  project_id = project_id_node ? project_id_node.content : nil
  story_id_node = doc.xpath("/activity/stories/story/id").first
  story_id = story_id_node ? story_id_node.content : nil

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
    story_url = "https://www.pivotaltracker.com/projects/#{project_id}?story_id=#{story_id}"
    message = "#{description}\n#{story_url}"
    escaped_message = URI.escape(message, ':/?=" ')
    token.request :post, "/api/v1/messages/?body=#{escaped_message}"

    "Posted: #{description}"
  else
    "Ignored"
  end
end
