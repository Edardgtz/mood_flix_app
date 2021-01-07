class Api::MoviesController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'json'
  require "google/cloud/language"


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
   
  end

  def find_unique_moods
    @moods = Mood.all
    @titles = []
  
    @moods.each do |mood|
      @titles << mood.title_id
    end
  
    @uniq_titles = @titles.uniq
    
    @uniq_moods = []
    @uniq_titles.each do |title_id|
      uniq_mood = Mood.find_by(title_id: title_id)
      @uniq_moods << uniq_mood
    end
    # p @uniq_moods
  end

  def find_user_score_range
    @user_score_range = []
      
    positve_limit = @user_input_sentiment_score.to_f + 0.30
    
    negative_limit = @user_input_sentiment_score.to_f - 0.30

    @user_score_range = Mood.where(sentiment_score: negative_limit..positve_limit)
  end

  def find_entity_match
    find_unique_moods()
    
    @title_entities = []
    @entity_match = []
    p @user_input_entities
    @uniq_titles.each do |title|
      match = false
      @title_entities = Entity.where(title_id: title)
      # p @title_entities
      @title_entities.each do |entity|
        # p entity
        @user_input_entities.each do |user_entity|
          p "#{user_entity[:name]} == #{entity.entity_name} = ?"
          if user_entity[:name] ==  entity.entity_name
            match = true
          end
          if match == true
            @entity_match << entity.title_id
          end
        end
      end
    end
    p @entity_match.length
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
      title1 = @user_score_range.sample
      title2 = @user_score_range.sample
      title3 = @user_score_range.sample
      title4 = @user_score_range.sample
      title5 = @user_score_range.sample
    else
      # selected_title = @entity_match.sample
      # @title_id = selected_title
      @titles = []
      p 'Line 160'
      p @entity_match
      @unique_titles = @entity_match.uniq
      p @unique_titles
      title1 = @entity_match.sample
      title2 = @entity_match.sample
      title3 = @entity_match.sample
      title4 = @entity_match.sample
      title5 = @entity_match.sample
    end
    # # p selected_title
    # numbers = [1,2,3,4,5,6,7,8,9,10]
    # rand = numbers.sample

    # request_similar_titles("https://movies-tvshows-data-imdb.p.rapidapi.com/?type=get-similar-movies&imdb=#{@unique_titles[rand]}")
    
    # @parsed_movie = JSON.parse(@results)

    # # pp @parsed_movie
    # zero_to_ninteen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
   
    # rand1 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand1 }
    # rand2 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand2 }
    # rand3 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand3 }
    # rand4 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand4 }
    # rand5 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand5 }
    # rand6 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand6 }
    # rand7 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand7 }
    # rand8 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand8 }
    # rand9 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand9 }
    # rand10 = zero_to_ninteen.sample
    # zero_to_ninteen.delete_if {|number| number == rand10 }

    # @similar_title1 = @unique_titles[rand]
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand2] && @parsed_movie['movie_results'][rand2]['imdb_id'] != []
    #   @similar_title2 = @parsed_movie['movie_results'][rand2]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand3] && @parsed_movie['movie_results'][rand3]['imdb_id'] != []
    #   @similar_title3 = @parsed_movie['movie_results'][rand3]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand4] && @parsed_movie['movie_results'][rand4]['imdb_id'] != []
    #   @similar_title4 = @parsed_movie['movie_results'][rand4]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand5] && @parsed_movie['movie_results'][rand5]['imdb_id'] != []
    #   @similar_title5 = @parsed_movie['movie_results'][rand5]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand6] && @parsed_movie['movie_results'][rand6]['imdb_id'] != []
    #   @similar_title6 = @parsed_movie['movie_results'][rand6]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand7] && @parsed_movie['movie_results'][rand7]['imdb_id'] != []
    #   @similar_title7 = @parsed_movie['movie_results'][rand7]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand8] && @parsed_movie['movie_results'][rand8]['imdb_id'] != []
    #   @similar_title8 = @parsed_movie['movie_results'][rand8]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand9] && @parsed_movie['movie_results'][rand9]['imdb_id'] != []
    #   @similar_title9 = @parsed_movie['movie_results'][rand9]['imdb_id']
    # end
    # if @parsed_movie && @parsed_movie['movie_results'] &&@parsed_movie['movie_results'][rand10] && @parsed_movie['movie_results'][rand10]['imdb_id'] != []
    #   @similar_title10 = @parsed_movie['movie_results'][rand10]['imdb_id']
    # end

    @title1 = title1
    @title2 = title2
    @title3 = title3
    @title4 = title4
    @title5 = title5
  end 

  def call_overview
    call_similar_movies()

    # titles = [@similar_title1, @title2, @title3, @similar_title4, @similar_title5, @similar_title6, @similar_title7, @similar_title8, @similar_title9, @similar_title10]

    titles = [@title1, @title2, @title3, @title4, @title5]
    titles = @unique_titles.shuffle

    @parsed_overview_movies = []
    p titles
    i = 0
    while i < titles.length
      p titles[i]
      request_overview_details("https://imdb8.p.rapidapi.com/title/get-overview-details?tconst=#{titles[i]}&currentCountry=US")

      parsed_results = JSON.parse(@results)

      if parsed_results && parsed_results['certificates'] && parsed_results['certificates']['US'] && parsed_results['certificates']['US'][0] && parsed_results['certificates']['US'][0]['ratingReason'] && parsed_results['certificates']['US'][0]['ratingReason'] != []
        @parsed_overview_movies << parsed_results
      end

      if @parsed_overview_movies.length == 6
        break
      end
      i += 1
    end
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


