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


  def index
    # @similar_movies = []
    # need to sort movies by sentiment score
    # String input to be analyzed

    text_content = params[:user_input]

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

    # Entity Analysis code here
    # create a variable to store user_input_entities as an array of hashes


    # @mood_titles = Mood.where(user_input_score: params[:user_score])
    # I need to iterate through the the moods and push moods into 3 arrays. clearly positive, clearly negative, and mixed. 
    # Then need to analyze the movies to see if they make sense in their category. 
    # From here I can write a conditional that selects from one of these arrays based on user_input_score.

    def find_user_match
      @user_score_range = []
      # p '*---------*---------*---------*---------*---------*'
      # p 'line: 77 @user_input_sentiment_score'
      # p @user_input_sentiment_score
      # p '*---------*---------*---------*---------*---------*'
      positve_limit = @user_input_sentiment_score.to_f + 0.30
      # p '*---------*---------*---------*---------*---------*'
      # p "positive_limit: #{positve_limit}"
      negative_limit = @user_input_sentiment_score.to_f - 0.30
      # p "negative_limit: #{negative_limit}"

      @user_score_range = Mood.where(sentiment_score: negative_limit..positve_limit)

      # # p '*---------*---------*---------*---------*---------*'
      p @user_score_range
      p @user_score_range.length
     
      # write entity matching logic here. Need to have entity column and data for this.
      

    end

    


    def call_similar_movies
      find_user_match()
      # p @selected_categorie
      selected_title = @user_score_range.sample
      # p 'Line: 127 *-------------*-------------*-------------*'
      # p selected_title
      @title_id = selected_title.title_id
      # p @title_id
      # Have to add IMDB similar title url here. Interpolate user_score_match
      request_similar_titles("https://movies-tvshows-data-imdb.p.rapidapi.com/?type=get-similar-movies&imdb=#{@title_id}")
      # p @results
      
      @parsed_movie = JSON.parse(@results)

      # I can call a method here to get all title ids from the similar call and run those through the plot call. then run nlp entity on the longest plot text(number 4 in plot array.). create arrays of entities of each title then select title ids which match user entities in any way. pass the selected title ids to overview call.


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

      @similar_title1 = @parsed_movie['movie_results'][rand1]['imdb_id']
      p @similar_title1
      @similar_title2 = @parsed_movie['movie_results'][rand2]['imdb_id']
      p @similar_title2
      @similar_title3 = @parsed_movie['movie_results'][rand3]['imdb_id']
      p @similar_title3
      @similar_title4 = @parsed_movie['movie_results'][rand4]['imdb_id']
      p @similar_title4
      @similar_title5 = @parsed_movie['movie_results'][rand5]['imdb_id']
      p @similar_title5
    end 
    

    def call_overview
      call_similar_movies()

      titles = [@similar_title1, @similar_title2, @similar_title3, @similar_title4, @similar_title5]
      @parsed_overview_movies = []
      # p titles
      titles.each do |title|
        request_overview_details("https://imdb8.p.rapidapi.com/title/get-overview-details?tconst=#{title}&currentCountry=US")

        parsed_results = JSON.parse(@results)
        @parsed_overview_movies << parsed_results
      end
      p @parsed_overview_movies
    end

    call_overview()

    render 'index.json.jb'
  end
  
  
end


