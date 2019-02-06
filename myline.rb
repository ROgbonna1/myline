require 'sinatra'
require 'sinatra/reloader'
require 'google_maps_service'
require 'net/http'
require 'uri'
require 'json'

# Setup global parameters
GoogleMapsService.configure do |config|
  config.key = 'AIzaSyARPpg-mcc-UvyecsGreHSHfYfshI87epU'
  config.retry_timeout = 20
  config.queries_per_second = 10
end

# Initialize client using global parameters
gmaps = GoogleMapsService::Client.new

get "/" do
  erb :index
end

post "/search" do
  from = params[:origin]
  to = params[:destination]
  mode = params[:mode]
  results = gmaps.directions(to, from, mode: mode, alternatives: false).first
  @duration = results[:legs].first[:duration][:text]
  @distance = results[:legs].first[:distance][:text]
  erb :results
  
  # Grabbing JSON from Yelp Fusion API call
  uri = URI('https://api.yelp.com/v3/businesses/search') # base uri for yelp api
  parameters = { 'term' => 'restaurant', 'location' => from } # search parameters
  uri.query = URI.encode_www_form(parameters) # the .encode_www_form methods formats my parameters hash into query parameter format. The .query method sets this as the query for my uri.
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  restaurants = http.get(uri.request_uri, initheader = { 'Authorization' => 'Bearer wPydcDY5ij_piBDddbiBECp2bE4PUR1rDqjcfsZbRF8aVQd1TONWk6Vlyu837T3HvQrSLxejSN4RQYz2ds-rdgghQz8AFIPtJ1J37oAUHt-BJxz9mN3nyCLnBU5aXHYx' })
  @restaurants = restaurants.body
  
end