require 'uri'
require 'base64'
require 'net/http'
require 'conjur/api'
require 'rest_client'
require 'json'

ns = ARGV.shift      or raise "Expecting ns argument"
api_key = ARGV.shift or raise "Expecting api_key argument"

def service_b_uri(id)
  URI("https://service-accel-#{id}-demo-conjur.herokuapp.com")
end

puts "Warming up Heroku services"

Net::HTTP.get(service_b_uri(1))
Net::HTTP.get(service_b_uri(2))

puts "\tdone"

puts "Making initial request"

ENV['CONJUR_ENV']     = 'production'
ENV['CONJUR_ACCOUNT'] = 'sandbox'
token = Conjur::API.authenticate "host/#{ns}/services/a/1", api_key
response = JSON.parse RestClient.get(service_b_uri(1).to_s, { authorization: "Token token=\"#{Base64.strict_encode64 token.to_json}\"" }).body
service_token = response['service_token']

puts "\tdone"

puts "Making requests with service token to services B.1 and B.2"

threads = [ 1, 2 ].map do |i|
  Thread.new do
    10.times do
      RestClient.get(service_b_uri(i).to_s, { authorization: "Token token=\"#{service_token}\"" })
      $stdout.write '.'
    end
  end
end

threads.map(&:join)

$stdout.write "\n"
puts "\tdone"
