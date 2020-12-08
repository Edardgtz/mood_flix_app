class Api::MoviesController < ApplicationController
  require 'unirest'
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'json'

  def request_api(url)
    url = URI.parse(url)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    

    response = http.request(request)
    @details = response.body

  end
    
  

  def index
    title_search = params[:tconst]
    request_api("https://imdb8.p.rapidapi.com/title/get-details?tconst=0944756")
    
    render 'index.json.jb'
  end

  
end


