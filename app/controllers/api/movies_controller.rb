class Api::MoviesController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'json'
  require "google/cloud/language"
  require 'benchmark' 

  # require 'test_helper'
  # require 'rails/performance_test_help'


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

  def find_user_score_range
    # store the users input range
    @user_score_range = []
      
    positve_limit = @user_input_sentiment_score.to_f + 0.30
    
    negative_limit = @user_input_sentiment_score.to_f - 0.30

    @user_score_range = Mood.where(sentiment_score: negative_limit..positve_limit)
  end

  def find_entity_match
    find_unique_moods()
    
    # create variables to store matches and their entities
    @title_entities = []
    @entity_match = []
    p @user_input_entities
    # iterate @uniq_titles
    @uniq_titles.each do |title|
      # assign boolean value
      match = false
      # create varible to print info outside the loop
      et = title
      # Capture the titles entities
      @title_entities = Entity.where(title_id: title)
      p @title_entities.count
      # iterate through the titles entities
      @title_entities.each do |entity|
        # p et
        # assign var to p outside loop
        et = entity.entity_name
        # iterate through user's entities
        @user_input_entities.each do |user_entity|
          # p "#{user_entity[:name]} == #{entity.entity_name} = ?"
          # assign var to particular user entity to p out of loop
          @u_e_n = user_entity[:name]
          # Compare user entity and title entity
          if user_entity[:name] ==  entity.entity_name
            p "#{user_entity[:name]} == #{entity.entity_name} = Match!!!!!!"
            # trigger consequent conditional 
            match = true
          end
          # p match
        end
        #  add only matches
        if match == true
          p "#{@u_e_t} == #{et} = Match!!!!!!"
          # array of titles from matches
          @entity_match << entity.title_id
        end
        # p "Line: 159 - @entity_match: #{@entity_match}"
      end
    end

  end

  def generate_similar_movies

    index = 0
    @titles_for_overview = []
    p 'Line: 212 - @randomly_selected_titles Length:'
    p  @randomly_selected_titles.length
    
    p "Line: 215 - @titles_for_overview.count = #{@titles_for_overview.count}"
    counter = 0
    @randomly_selected_titles.each do |title|
      if counter == 5
        break
      else
        p 'LIne: 227 - @randomly_selected_titles => title:'
        p title

        request_similar_titles("https://movies-tvshows-data-imdb.p.rapidapi.com/?type=get-similar-movies&imdb=#{title}")
        
        @parsed_movie = JSON.parse(@results)

        # pp @parsed_movie
        zero_to_ninteen = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
      
        rand1 = zero_to_ninteen.sample
        zero_to_ninteen.delete_if {|number| number == rand1 }
        rand2 = zero_to_ninteen.sample
        zero_to_ninteen.delete_if {|number| number == rand2 }
        rand3 = zero_to_ninteen.sample
        zero_to_ninteen.delete_if {|number| number == rand3 }
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

        p 'Line: 248 - zero_to_ninteen:'
        p zero_to_ninteen
        # @titles_for_overview << title
        p @titles_for_overview
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand1] && @parsed_movie['movie_results'][rand1]['imdb_id'] != [] && @parsed_movie['movie_results'][rand1]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand1]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand2] && @parsed_movie['movie_results'][rand2]['imdb_id'] != [] && @parsed_movie['movie_results'][rand2]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand2]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand3] && @parsed_movie['movie_results'][rand3]['imdb_id'] != [] && @parsed_movie['movie_results'][rand3]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand3]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand4] && @parsed_movie['movie_results'][rand4]['imdb_id'] != [] && @parsed_movie['movie_results'][rand4]['imdb_id'] != nil
          @titles_for_overview << @similar_title4
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand5] && @parsed_movie['movie_results'][rand5]['imdb_id'] != [] && @parsed_movie['movie_results'][rand5]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand5]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand6] && @parsed_movie['movie_results'][rand6]['imdb_id'] != [] && @parsed_movie['movie_results'][rand6]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand6]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand7] && @parsed_movie['movie_results'][rand7]['imdb_id'] != [] && @parsed_movie['movie_results'][rand7]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand7]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand8] && @parsed_movie['movie_results'][rand8]['imdb_id'] != [] && @parsed_movie['movie_results'][rand8]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand8]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand9] && @parsed_movie['movie_results'][rand9]['imdb_id'] != [] && @parsed_movie['movie_results'][rand9]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand9]['imdb_id']
        end
        if @parsed_movie && @parsed_movie['movie_results'] && @parsed_movie['movie_results'][rand10] && @parsed_movie['movie_results'][rand10]['imdb_id'] != [] && @parsed_movie['movie_results'][rand10]['imdb_id'] != nil
          @titles_for_overview << @parsed_movie['movie_results'][rand10]['imdb_id']
        end
        index += 1
        counter = counter + 1
        p "line: 287"
        p "Length: @titles_for_overview - #{@titles_for_overview.length}"
        p "Content: @titles_for_overview - #{@titles_for_overview}"
      end
    end
  end

  def call_similar_movies
    find_user_score_range()
    find_entity_match()

    # could create a sentiment route for when no entity matches user input.
    if @entity_match == []
      @randomly_selected_titles = []
      @user_score_range.each do |mood|
        @randomly_selected_titles << mood.title_id
      end

      generate_similar_movies()
      
      p "In @user_score_range..."
    else
      # selected_title = @entity_match.sample
      # @title_id = selected_title
      @titles = []
      p 'Line: 178 - @entity_match'
      p "Length: #{@entity_match.length}"
      p "Content: #{@entity_match}"
      @unique_titles = @entity_match.uniq
      p "Line: 182 - @unique_titles: #{@unique_titles}"
      @number_of_unique_titles = @unique_titles.count
      @randomly_selected_titles = []
      i = 0
      if @unique_titles.count == nil
        p 'Nil Could return an message here saying no matches found'
      else
        while i < @unique_titles.length
          p "Line: 190 - @unique_titles[i]: #{@unique_titles[i]}"
          @randomly_selected_titles << @unique_titles[i]
          i += 1
          p "Line 193 - @randomly_selected_titles: #{@randomly_selected_titles}"
        end

      end
      generate_similar_movies()
    end
    # # p selected_title
    # numbers = [1,2,3,4,5,6,7,8,9,10]
    # rand = numbers.sample
    


    
    
    # @title1 = title1
    # @title2 = title2
    # @title3 = title3
    # @title4 = title4
    # @title5 = title5
  end 

  def call_overview
    call_similar_movies()

    titles = @titles_for_overview

    # titles = [@title1, @title2, @title3, @title4, @title5]
    p "Line: 341 - Unshuffled titles => #{titles}"
    titles = @titles_for_overview.shuffle
    titles = titles.uniq
    p "Line: 343 - Shuffled titles => #{titles}"
    @parsed_overview_movies = []
    # p titles
    i = 0
    while i < titles.length
      # random = rand(0..titles.length)
      if titles[i] != nil && titles[i] != 0
        p titles[i]
        request_overview_details("https://imdb8.p.rapidapi.com/title/get-overview-details?tconst=#{titles[i]}&currentCountry=US")

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
    call_sentiment(params[:user_input])

  
    call_entity(params[:user_input])
  
    overview = Benchmark.measure { 
      call_overview()}
    # call_overview()



    render 'index.json.jb'
    p overview
    p @uniq_titles.count

  end
  
  
end


