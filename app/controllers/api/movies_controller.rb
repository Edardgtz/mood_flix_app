class Api::MoviesController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'json'
  require "google/cloud/language"
  require 'benchmark' 

  def request_overview_details(url)
    url = URI(url)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["x-rapidapi-key"] = "#{Rails.application.credentials.imdb_api[:api_key]}"
    request["x-rapidapi-host"] = 'imdb8.p.rapidapi.com'

    response = http.request(request)
    @results = response.read_body
  end
  
  def call_entity(text_content)
    @user_input_entities = []

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.analyze_entities document: document

    entities = response.entities

    entities.each do |entity|

      @user_input_entities << {name: entity.name, type: entity.type}
      # puts "Entity #{entity.name} #{entity.type}"

      # puts "URL: #{entity.metadata['wikipedia_url']}" if entity.metadata["wikipedia_url"]
    end
  end

  def find_entity_match
    @entity_names = []
    @user_input_entities.each do |user_entity|
      user_entity_name = user_entity[:name]
      @entity_names << user_entity_name
    end

    @entity_match = []
    @entity_names.each do |name|
      @entity_matches = Entity.where(entity_name: name)
      @entity_matches.each do |entity|
        @entity_match << entity.title_id
      end
    end

    # @entity_match = @entity_match.uniq
    # matches = []
    # @entity_match.each do |title|
    #   counter = 0
    #   entities = Entity.where(title_id: title)
    #   entities.each do |entity|
    #     p entity
    #     @user_input_entities.each do |user_entity|
    #       if entity.entity_name == user_entity[:name]
    #         counter = counter + 1
    #       end
    #     end
    #   end
    #   matches << {"#{title}": counter}
    # end
    # p matches
    # matches.each do |match|

    # end
    # p @entity_matches
    # p @entity_matches.count
    # p @entity_match.count
  end

  def call_overview
    find_entity_match()
    # p @entity_match
    titles = @entity_match.uniq
    # p titles
    # p titles.count
    # p "Line: 76 - Unshuffled titles => #{titles}"
    # titles = @titles_for_overview.shuffle
    titles = titles.shuffle
    # p "Line: 79 - Shuffled titles => #{titles}"
    @parsed_overview_movies = []
    i = 0
    while i < titles.length
      if titles[i] != nil && titles[i] != 0
        p titles[i]
        request_overview_details("https://imdb8.p.rapidapi.com/title/get-overview-details?tconst=#{titles[i]}&currentCountry=US").delay

        parsed_results = JSON.parse(@results)
        # p parsed_results
        if parsed_results && parsed_results['certificates'] && parsed_results['certificates']['US'] && parsed_results['certificates']['US'][0] && parsed_results['certificates']['US'][0]['ratingReason'] && parsed_results['plotSummary']
          # p parsed_results
          @parsed_overview_movies << parsed_results
        end
        # p @parsed_overview_movies.count
        if @parsed_overview_movies.length == 10
          # p @parsed_overview_movies
          break
        end
        i += 1
        # Write logic to delete mood and entities for titles that do not display properly here
      else
        i += 1
      end
    end
  end

  def index
    call_entity(params[:user_input])
    # overview = Benchmark.measure { 
      # call_overview()}
    call_overview()
    render 'index.json.jb' 
  end
  
  
end


