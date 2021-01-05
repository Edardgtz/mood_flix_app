class Api::MoviesController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'json'

  def request_similar_titles(url)
    url = URI(url)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["x-rapidapi-key"] = "#{Rails.application.credentials.imdb_api[:api_key]}"
    request["x-rapidapi-host"] = 'movies-tvshows-data-imdb.p.rapidapi.com'

    response = http.request(request)
    @results = response.read_body
  end

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
  
  def call_sentiment(text_content)

    # need to sort movies by sentiment score
    # String input to be analyzed

    require "google/cloud/language"

    language = Google::Cloud::Language.language_service

    document = { content: text_content, type: :PLAIN_TEXT }
    response = language.analyze_sentiment document: document

    sentiment = response.document_sentiment

    # puts "Overall document sentiment: (#{sentiment.score})"
    # puts "Sentence level sentiment:"

    sentences = response.sentences

    sentences.each do |sentence|
      sentiment = sentence.sentiment
      @user_input_sentiment_score = "#{sentiment.score}"
      # {sentence.text.content}: 
    end
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
    # p @user_input_entities
  end

  def find_user_score_range
    @user_score_range = []
      
    positve_limit = @user_input_sentiment_score.to_f + 0.30
    
    negative_limit = @user_input_sentiment_score.to_f - 0.30

    @user_score_range = Mood.where(sentiment_score: negative_limit..positve_limit)

    # p @user_score_range
    # p @user_score_range.length
  end

  def find_entity_match
    select_titles = []
    @user_score_range.each do |mood|
      select_titles << mood.title_id
    end
    # p select_titles
    @title_entities = []
    @entity_match = []
    # p @user_input_entities
    select_titles.each do |title|

      @title_entities = Entity.where(title_id: title)
      # p @title_entities
      @title_entities.each do |entity|
        # p entity
        @user_input_entities.each do |user_entity|
          # p user_entity[:name] 
          # p entity.entity_name
          if user_entity[:name] ==  entity.entity_name
            p user_entity[:name] 
            p entity.entity_name
            @entity_match << entity.title_id
            # p @entity_match
          end
        end
      end
    end
    p @entity_match
  end

  def find_user_match
    find_user_score_range()
    find_entity_match()
  end

  def call_similar_movies

    find_user_match()

    if @entity_match == []
      selected_title = @user_score_range.sample
      @title_id = selected_title.title_id
    else
      selected_title = @entity_match.sample
      @title_id = selected_title
    end
    # p selected_title
    # Have to add IMDB similar title url here. Interpolate user_score_match
    request_similar_titles("https://movies-tvshows-data-imdb.p.rapidapi.com/?type=get-similar-movies&imdb=#{@title_id}")
    # p @results
    
    @parsed_movie = JSON.parse(@results)

    # pp @parsed_movie
    zero_to_ninteen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
    # p @parsed_movie
    rand1 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand1 }
    # p rand1
    # p zero_to_ninteen.length
    rand2 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand2 }
    # p rand2
    rand3 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand3 }
    # p rand3
    rand4 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand4 }

    rand5 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand5 }
    rand6 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand6 }
    rand7 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand7 }
    rand8 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand8 }
    rand9 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand9 }
    rand10 = zero_to_ninteen.sample
    zero_to_ninteen.delete_if {|number| number == rand10 }
  
    p @parsed_movie['movie_results'][rand1]['imdb_id']
    @similar_title1 = @title_id
    # p @similar_title1
    @similar_title2 = @parsed_movie['movie_results'][rand2]['imdb_id']
    # p @similar_title2
    @similar_title3 = @parsed_movie['movie_results'][rand3]['imdb_id']
    # p @similar_title3
    @similar_title4 = @parsed_movie['movie_results'][rand4]['imdb_id']
    # p @similar_title4
    @similar_title5 = @parsed_movie['movie_results'][rand5]['imdb_id']
    @similar_title6 = @parsed_movie['movie_results'][rand6]['imdb_id']
    @similar_title7 = @parsed_movie['movie_results'][rand7]['imdb_id']
    @similar_title8 = @parsed_movie['movie_results'][rand8]['imdb_id']
    @similar_title9 = @parsed_movie['movie_results'][rand9]['imdb_id']
    @similar_title10 = @parsed_movie['movie_results'][rand10]['imdb_id']

    title1 = @user_score_range.sample
    title2 = @user_score_range.sample
    title3 = @user_score_range.sample
    title4 = @user_score_range.sample
    @title1 = title1.title_id
    @title2 = title2.title_id
    @title3 = title3.title_id
    @title4 = title4.title_id
  end 

  def call_overview
    call_similar_movies()

    titles = [@similar_title1, @similar_title2, @similar_title3, @similar_title4, @similar_title5, @similar_title6, @similar_title7, @similar_title8, @similar_title9, @similar_title10]

    # titles = [@title1, @title2, @title3]

  
    @parsed_overview_movies = []
    p titles
    i = 0
    while i < titles.length
      p titles[i]
      request_overview_details("https://imdb8.p.rapidapi.com/title/get-overview-details?tconst=#{titles[i]}&currentCountry=US")

      parsed_results = JSON.parse(@results)
      # @parsed_overview_movies << parsed_results
      if parsed_results && parsed_results['certificates'] && parsed_results['certificates']['US'] && parsed_results['certificates']['US'][0] && parsed_results['certificates']['US'][0]['ratingReason'] && parsed_results['certificates']['US'][0]['ratingReason'] != []
        p parsed_results
        @parsed_overview_movies << parsed_results
      end
      # @parsed_overview_movies << parsed_results
      if @parsed_overview_movies.length == 5
        break
      end
      i += 1
    end
    # p @parsed_overview_movies
  end

  def index
   
    call_sentiment(params[:user_input])
    
    call_entity(params[:user_input])

    find_user_match()

    call_similar_movies()

    call_overview()

    render 'index.json.jb'
  end
  
  
end


