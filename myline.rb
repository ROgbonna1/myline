require 'sinatra'
require 'sinatra/reloader'
require 'google_maps_service'
require 'net/http'
require 'uri'
require 'json'


def yelp_search(search_params = {limit: 10, location: 'New York, NY'}) # Grabs JSON from Yelp Fusion API call
  uri = URI('https://api.yelp.com/v3/businesses/search') # base uri for yelp api
  parameters = { 'term' => 'restaurant', 'limit' => search_params[:limit], 'sort_by' => 'rating', 'location' => search_params[:location] } # search parameters
  uri.query = URI.encode_www_form(parameters) # the .encode_www_form methods formats my parameters hash into query parameter format. The .query method sets this as the query for my uri.
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  restaurants = http.get(uri.request_uri, initheader = { 'Authorization' => 'Bearer wPydcDY5ij_piBDddbiBECp2bE4PUR1rDqjcfsZbRF8aVQd1TONWk6Vlyu837T3HvQrSLxejSN4RQYz2ds-rdgghQz8AFIPtJ1J37oAUHt-BJxz9mN3nyCLnBU5aXHYx' })
  results = JSON.parse(restaurants.body, symbolize_names: true)
  results[:businesses]
end

def yelp_list_businesses(results, search_params = { limit: 50})
  list = results[:businesses].map do |business|
    { 
      name: business[:name], 
      location: [business[:coordinates][:latitude], business[:coordinates][:longitude]],
      url: business[:url]
    }
  end
  list[0...search_params[:limit]]
end


def travel_delta(location1, location2, destination, travel_mode)
  distance_from_location1 = trip_time(destination, location1, travel_mode)
  distance_from_location2 = trip_time(destination, location2, travel_mode)
  (distance_from_location1 - distance_from_location2).abs
end

helpers do
  def google_directions(origin, destination)
    uri = URI('https://www.google.com/maps/dir/?api=1')
    parameters = { 'api' => '1', 'origin' => origin, 'destination' => destination }
    uri.query = URI.encode_www_form(parameters)
    uri.to_s
  end
  
  def trip_time(to, from, travel_mode)
    gmaps = GoogleMapsService::Client.new(key: 'AIzaSyARPpg-mcc-UvyecsGreHSHfYfshI87epU')
    trip = gmaps.directions(to, from, mode: travel_mode, alternatives: false).first
    trip[:legs].first[:duration][:value]
  end
  
  def coordinates(business)
    [business[:coordinates][:latitude], business[:coordinates][:longitude] ]
  end
end

get "/" do
  erb :index
end

post "/search" do
  @location1 = params[:location1]
  @location2 = params[:location2]
  mode = params[:mode]
  
  restaurants = (yelp_search(location: @location1, limit: 10) + 
                  yelp_search(location: @location2, limit: 10)).uniq
  
  @restaurants = restaurants.sort_by do |restaurant|
    travel_delta(@location1, @location2, coordinates(restaurant), mode)
  end
  
  erb :results
end