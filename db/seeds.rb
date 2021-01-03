

def call_api

  @genres = ['comedy', 'animation', 'adventure', 'horror', 'mystery', 'action', 'fantasy', 'scifi', 'romance', 'biography', 'crime', 'documentary', 'family', 'film-noir', 'history', 'musical', 'sport', 'thriller', 'war', 'western', 'drama']

  @moods = ['happy', 'sad',]

  require 'uri'
  require 'net/http'
  require 'json'
  require 'openssl'

  index = 0
  while index < @genres.length
    url = URI("https://imdb8.p.rapidapi.com/title/get-popular-movies-by-genre?genre=/chart/popular/genre/#{@genres[index]}")

    p "*-----------**-----------**-----------**-----------**-----------*"
    p @genres[index]
    p "*-----------**-----------**-----------**-----------**-----------*"

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(url)
    request["x-rapidapi-key"] = "#{Rails.application.credentials.imdb_api[:api_key]}"
    request["x-rapidapi-host"] = 'imdb8.p.rapidapi.com'

    response = http.request(request)
    @details = JSON.parse(response.read_body)
    
    @title_ids = []
    i = 0
    while i < @details.length
      titles_split = @details[i].split ('/') 
      @title_ids << titles_split[2]
      i += 1
    end

    i = 0
    while i < @title_ids.length
      if @genres[index] == "western"  || @genres[index] == "horror" || @genres[index] == "mystery" || @genres[index] == "scifi" || @genres[index] == "history" || @genres[index] == "sport" || @genres[index] == "war" || @genres[index] == "action" 
        i += 1
        break
      elsif @genres[index] == "adventure" || @genres[index] == "documentary" || @genres[index] == "fantasy" || @genres[index] == "romance" || @genres[index] == "family" || @genres[index] == "musical" || @genres[index] == "thriller" || @genres[index] == "animation" || @genres[index] == "comedy" || @genres[index] == "biography" || @genres[index] == "crime" || @genres[index] == "film-noir" || @genres[index] == "drama"
        mood = Mood.create(mood: @moods[1], title_id: @title_ids[i])
        i += 1
      end
      p mood
    end
    index += 1
  end
end

# call_api()

def call_nlp

  text_content = "Miami detectives Mike Lowrey and Marcus Burnett must face off against a mother-and-son pair of drug lords who wreak vengeful havoc on their city."

  require "google/cloud/language"

  language = Google::Cloud::Language.language_service

  document = { content: text_content, type: :PLAIN_TEXT }
  response = language.analyze_sentiment document: document

  sentiment = response.document_sentiment

  puts "Overall document sentiment: (#{sentiment.score})"
  puts "Sentence level sentiment:"

  sentences = response.sentences

  sentences.each do |sentence|
    sentiment = sentence.sentiment
    puts "#{sentence.text.content}: (#{sentiment.score})"
  end

end

# call_nlp()



# @moods = Mood.all
# @titles = []
# @moods.each do |mood|
#   @titles << mood.title_id
# end
# uniq_titles = @titles.uniq

# uniq_mood_titles = []
# uniq_titles.each do |title|
#   search_title = Mood.where(title_id: title)
#   uniq_mood_titles << search_title[0]
# end

# @sad_titles = []
# @happy_titles = []
# uniq_mood_titles.each do |mood|
#   if mood.mood == 'sad'
#     @sad_titles << mood.title_id
#   else
#     @happy_titles << mood.title_id
#   end
# end

@moods = Mood.all
@sad_mood = []
@happy_mood = []
@moods.each do |mood|
  if mood.mood == 'sad'
    @sad_mood << mood
  else
    @happy_mood << mood
  end
end


# p '*------------*------------*------------*------------*'
# p'Line: 122'
# p @happy_mood.length
# p @sad_mood.length
# p '*------------*------------*------------*------------*'

@happy_mood = @happy_mood.sort
@sad_mood = @sad_mood.sort

def call_plots
  @sad_mood.each do |mood|
    if mood.sentiment_score == nil
      require 'uri'
      require 'net/http'
      require 'openssl'
      require 'json'

      

      url = URI("https://imdb8.p.rapidapi.com/title/get-plots?tconst=#{mood.title_id}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(url)
      request["x-rapidapi-key"] = "#{Rails.application.credentials.imdb_api[:api_key]}"
      request["x-rapidapi-host"] = 'imdb8.p.rapidapi.com'

      response = http.request(request)
      unparsed_plots = response.read_body
      @plots = JSON.parse(unparsed_plots)

      #Confirm data
      # p '*------------*------------*------------*------------*'
      # p 'Line: 163'
      # p @plots['plots'][0]['text'].length
      # p @plots['plots'][0]['text']
      # p '*------------*------------*------------*------------*'
      #Parse plots
      i = 0
      @array_of_plots = []
      if @plots['plots'] == nil
        i += 1
      else
        while i < @plots['plots'].length
          p '*------------*------------*------------*------------*------------*'
          p 'Line: 175'
          p mood.id
          p mood.id
          p mood.id
          p @plots['plots'][i]['text']
          p '*------------*------------*------------*------------*------------*'
          
          # String input to be analyzed
          text_content = @plots['plots'][i]['text']

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
            @sentiment_score = "#{sentiment.score}"
            # {sentence.text.content}: 
          end
          @array_of_plots << @sentiment_score
          i += 1
        end
      end
      p '*------------*------------*------------*------------*'
      p @sentiment_score
      p 'Line: 207'
      p @array_of_plots
      p '*------------*------------*------------*------------*'

      @average_score = @array_of_plots.inject{ |sum, el| sum + el }.to_f / @array_of_plots.size
      p 'Before:'
      p '*------------*------------*------------*------------*'
      p mood
      p '*------------*------------*------------*------------*'
      mood.sentiment_score = @average_score
      mood.save
      p 'After:'
      p '*------------*------------*------------*------------*'
      p mood
      p '*------------*------------*------------*------------*'
      p @average_score
      p '*------------*------------*------------*------------*'
    end
  end
  p '*------------*------------*------------*------------*'
  p 'Line: 226'
  p @array_of_plots
  p '*------------*------------*------------*------------*'
end

# call_plots()

def seed_entities
  @moods = Mood.all
  @titles = []
  @moods.each do |mood|
    @titles << {title_id: mood.title_id, mood_id: mood.id}
  end

  @uniq_titles = @titles.uniq
  p @uniq_titles
  @unique_moods = []
  @uniq_titles.each do |ids|
    @moods.each do |mood|
      if mood.id == ids[:mood_id]
        @unique_moods << mood
      end
    end
  end
  p @unique_moods.count


  # p @unique_titles.count
#   @mood.each do |mood|
#     require 'uri'
#     require 'net/http'
#     require 'openssl'
#     require 'json'

    

#     url = URI("https://imdb8.p.rapidapi.com/title/get-plots?tconst=#{mood.title_id}")

#     http = Net::HTTP.new(url.host, url.port)
#     http.use_ssl = true
#     http.verify_mode = OpenSSL::SSL::VERIFY_NONE

#     request = Net::HTTP::Get.new(url)
#     request["x-rapidapi-key"] = "#{Rails.application.credentials.imdb_api[:api_key]}"
#     request["x-rapidapi-host"] = 'imdb8.p.rapidapi.com'

#     response = http.request(request)
#     unparsed_plots = response.read_body
#     @plots = JSON.parse(unparsed_plots)
#   end
end

seed_entities()