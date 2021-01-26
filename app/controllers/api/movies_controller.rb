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

  def find_unique_moods
    # Gathering  all moods, 
    @moods = Mood.all
    @titles = []
    
    # Isolating and capturing each moods title_id
    @moods.each do |mood|
      @titles << mood.title_id
    end
    
    # filtering duplicates
    @uniq_titles = @titles.uniq
    
    # Isolating and capturing unique moods
    @uniq_moods = []
    @uniq_titles.each do |title_id|
      uniq_mood = Mood.find_by(title_id: title_id)
      @uniq_moods << uniq_mood
    end
    # p @uniq_moods
  end

  

  def find_entity_match
    find_unique_moods()
    
    # create variables to store matches and their entities
    @title_entities = []
    @entity_match = []
    # p @user_input_entities
    # iterate @uniq_titles
    @uniq_titles.each do |title|
      # assign boolean value
      match = false
      # create varible to print info outside the loop
      et = title
      # Capture the titles entities
      @title_entities = Entity.where(title_id: title)
      # p @title_entities.count
      # iterate through the titles entities
      @title_entities.each do |entity|
        # p et
        # assign var to p outside loop
        et = entity.entity_name
        # iterate through user's entities
        @user_input_entities.each do |user_entity|
          # p "#{user_entity[:name]} == #{entity.entity_name} = ?"
          # assign var to particular user entity to p out of loop
          @u_e_t = user_entity[:name]
          # Compare user entity and title entity
          if user_entity[:name] ==  entity.entity_name
            # p "#{user_entity[:name]} == #{entity.entity_name} = Match!!!!!!"
            # trigger consequent conditional 
            match = true
          end
          # p match
        end
        #  add only matches
        if match == true
          # p "#{@u_e_t} == #{et} = Match!!!!!!"
          # array of titles from matches
          @entity_match << entity.title_id
        end
        # p "Line: 159 - @entity_match: #{@entity_match}"
      end
    end

  end

  

  

  def call_overview
    # call_similar_movies()
    find_entity_match()
    # p @entity_match

    # titles = @titles_for_overview
    titles = @entity_match.uniq
    # p  titles
    # titles = [@title1, @title2, @title3, @title4, @title5]
    # p "Line: 341 - Unshuffled titles => #{titles}"
    # titles = @titles_for_overview.shuffle
    titles = titles.shuffle

    # p "Line: 343 - Shuffled titles => #{titles}"
    @parsed_overview_movies = []
    
    i = 0
    while i < titles.length
  
      if titles[i] != nil && titles[i] != 0
        # p titles[i]
        request_overview_details("https://imdb8.p.rapidapi.com/title/get-overview-details?tconst=#{titles[i]}&currentCountry=US").delay

        parsed_results = JSON.parse(@results)

        if parsed_results && parsed_results['certificates'] && parsed_results['certificates']['US'] && parsed_results['certificates']['US'][0] && parsed_results['certificates']['US'][0]['ratingReason'] && parsed_results['certificates']['US'][0]['ratingReason'] != []
          @parsed_overview_movies << parsed_results
        end
        if @parsed_overview_movies.length == 10
          break
        end
        i += 1
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


