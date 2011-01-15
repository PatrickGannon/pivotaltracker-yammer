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
#  body[0, 9] = "" if body =~ /^xml_body/ #for test harness
#  fake_body = %q|
#    <?xml version="1.0" encoding="UTF-8"?>
#    <activity>
#      <id type="integer">1031</id>
#      <version type="integer">175</version>
#      <event_type>story_update</event_type>
#      <occurred_at type="datetime">2009/12/14 14:12:09 PST</occurred_at>
#      <author>James Kirk</author>
#      <project_id type="integer">26</project_id>
#      <description>James Kirk accepted &quot;More power to shields&quot;</description>
#      <stories>
#        <story>
#          <id type="integer">109</id>
#          <url>https:///projects/26/stories/109</url>
#          <accepted_at type="datetime">2009/12/14 22:12:09 UTC</accepted_at>
#          <current_state>accepted</current_state>
#        </story>
#      </stories>
#    </activity>
#  |
  doc = Nokogiri::XML(body)
  description_node = doc.xpath("/activity/description").first
  description = description_node ? description_node.content : nil

  config = File.open('config/oauth.yml','r') do |f|
    YAML.load(f)
  end
  yammer_config = config["yammer"]

  consumer = OAuth::Consumer.new(yammer_config['consumer_key'],
    yammer_config['consumer_secret'],
    {:site=>"https://www.yammer.com"})
  params = {:oauth_token => yammer_config['token_key'],
    :oauth_token_secret => yammer_config['token_secret']}

  token = OAuth::ConsumerToken.from_hash(consumer, params)
  token.request :post, "/api/v1/messages/?body=#{URI.escape(description)}"

  "Posted: #{description}"
end
