require 'rubygems'
require 'sinatra'
require 'json'
require 'base64'
require 'slosilo'
require 'conjur/api'
require 'conjur-asset-environment'

$config = {}

ENV['CONJUR_ACCOUNT'] = 'sandbox'
ENV['CONJUR_STACK']   = 'v4'
raise "No NS provided" unless ns = $config[:ns] = ENV['NS']

raise "No SERVICE_ID provided"   unless service_id = ENV['SERVICE_ID']
raise "No SERVICE_API_KEY provided" unless service_api_key = ENV['SERVICE_API_KEY']

environment = Conjur::API::new_from_key("host/#{ns}/services/b/#{service_id}", service_api_key).environment("#{ns}/services/b")

$config[:key] = Slosilo::Key.new(environment.variable('shared-secret').value)

helpers do
  def key; $config[:key]; end
  def ns;  $config[:ns];  end

  def request_headers
    env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
  end

  def authorize_by_self
    key.token_valid?(@token)
  end

  def authorize_by_conjur
    api = Conjur::API::new_from_token @token
    resource = api.resource "sandbox:service:#{ns}/services/b"
    begin
      if resource.permitted?('execute')
        @service_token = Base64.strict_encode64 key.signed_token(@token['data']).to_json
        return true
      end
    rescue RestClient::Unauthorized
    end
    false
  end

  def authorize
    token = request_headers['authorization']
    return status(401) unless token
    return status(403) unless token.to_s[/^Token token="(.*)"/]
    @token = JSON.parse(Base64.decode64($1))

    halt(403) unless authorize_by_self || authorize_by_conjur
  end
end

before do
  authorize
end

get '/' do
  response = {
    message: 'OK'
  }
  if @service_token
    response[:service_token] = @service_token
  end

  response.to_json
end
