
def select_all_unique_titles
  @moods = Mood.all
  @titles = []
  @moods.each do |mood|
    @titles << mood.title_id
  end
  @uniq_titles = @titles.uniq
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
    @sentiment_score = "#{sentiment.score}"
    # {sentence.text.content}: 
  end
end

def call_entity(text_content)
  @title_entities = []

  require "google/cloud/language"

  language = Google::Cloud::Language.language_service

  document = { content: text_content, type: :PLAIN_TEXT }
  response = language.analyze_entities document: document

  entities = response.entities

  entities.each do |entity|
    @title_entities << {name: entity.name, type: entity.type}
    # puts "Entity #{entity.name} #{entity.type}"

    # puts "URL: #{entity.metadata['wikipedia_url']}" if entity.metadata["wikipedia_url"]
  end
  p @title_entities
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

def call_imdb(imdb_url)
  require 'uri'
  require 'net/http'
  require 'openssl'
  require 'json'

  url = URI(imdb_url)

  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Get.new(url)
  request["x-rapidapi-key"] = "#{Rails.application.credentials.imdb_api[:api_key]}"
  request["x-rapidapi-host"] = 'imdb8.p.rapidapi.com'

  response = http.request(request)
  unparsed_results = response.read_body
  @results = JSON.parse(unparsed_results)
  # pp @results
end

def retrieve_top_rated_titles
  call_imdb("https://imdb8.p.rapidapi.com/title/get-top-rated-movies")
  # pp @results
  # p @results.length
  @top_rated_title_ids = []
  @results.each do |array|
    # p array['id']
    titles_split = array['id'].split ('/')
    @top_rated_title_ids << titles_split[2]
  end
  p @top_rated_title_ids.length
end

def filter_out_duplicate_titles
  retrieve_top_rated_titles()
  select_all_unique_titles()
  p @uniq_titles
  @top_rated_uniq_titles = []
  
  @top_rated_title_ids.each do |top_rated_title_id|
    dup = false
    @uniq_titles.each do |uniq_mood_title_id|
      if top_rated_title_id == uniq_mood_title_id
        dup = true
        p "#{top_rated_title_id} == #{uniq_mood_title_id} = Duplicate"
      end
    end
    if dup == false
      @top_rated_uniq_titles << top_rated_title_id
    end
  end
  p @top_rated_uniq_titles.count
end

# filter_out_duplicate_titles()

def find_unique_title_ids
  mood = Mood.where(id: 2501..2647)
  @uniq_mood_titles = []
  mood.each do |mood|
    @uniq_mood_titles << mood.title_id
  end
  p @uniq_mood_titles.length
  p @uniq_mood_titles
end

# find_unique_title_ids()

def seed_entities
  # find_unique_moods()
  # filter_out_duplicate_titles()
  find_unique_title_ids()

  @uniq_mood_titles.each do |mood|
    p mood
    call_imdb("https://imdb8.p.rapidapi.com/title/get-plots?tconst=#{mood}")
    @plots = @results
    p 'Line: 276'
    p @plots['plots'].length
    if @plots['plots'].length == 10
      call_entity(@plots['plots'][9]['text'])
    elsif @plots['plots'].length == 9
      call_entity(@plots['plots'][8]['text'])
    elsif @plots['plots'].length == 8
      call_entity(@plots['plots'][7]['text'])
    elsif @plots['plots'].length == 7
      call_entity(@plots['plots'][6]['text'])
    elsif @plots['plots'].length == 6
      call_entity(@plots['plots'][5]['text'])
    elsif @plots['plots'].length == 5
      call_entity(@plots['plots'][4]['text'])
    elsif @plots['plots'].length == 4
      call_entity(@plots['plots'][3]['text'])
    elsif @plots['plots'].length == 3
      call_entity(@plots['plots'][2]['text'])
    elsif @plots['plots'].length == 2
      call_entity(@plots['plots'][1]['text'])
    elsif @plots['plots'].length == 1
      call_entity(@plots['plots'][0]['text'])  
    end
  
    @title_entities.each do |entity|
      new_entity = Entity.create!(
        title_id: mood, 
        entity_name: entity[:name],
        entity_type: entity[:type]
      )
      p new_entity
    end
  end
end

# seed_entities()


def create_mood(title_id, sentiment_score)
  @mood = Mood.create!(
    title_id: title_id,
    sentiment_score: sentiment_score)
end

def obtain_average_sentiment_score
  i = 0
  @array_of_plots = []
  if @plots['plots'] == nil
    i += 1
  else
    while i < @plots['plots'].length
      call_sentiment(@plots['plots'][i]['text'])
      p @plots['plots'][i]['text']
      @array_of_plots << @sentiment_score
      i += 1
      p '*------------*------------*------------*'
    end  
    p '*------------*------------*------------*'
    p 'Line: 239'
    p @array_of_plots
    p '*------------*------------*------------*'
  end
  @average_score = @array_of_plots.inject{ |sum, el| sum + el }.to_f / @array_of_plots.size
end

def seed_unique_top_rated_titles
  filter_out_duplicate_titles()
  p @top_rated_uniq_titles
  @top_rated_uniq_titles.each do |top_rated_uniq_title|
    p top_rated_uniq_title
    @seed_title_id = top_rated_uniq_title
    call_imdb("https://imdb8.p.rapidapi.com/title/get-plots?tconst=#{top_rated_uniq_title}")
    @plots = @results

    obtain_average_sentiment_score()

    create_mood(@seed_title_id, @average_score)

    p 'After:'
    p '*------------*------------*------------*'
    p @mood
    p '*------------*------------*------------*'
    p @average_score
    p '*------------*------------*------------*'
  end
end

# seed_unique_top_rated_titles()


def imdb_dataset
  require 'csv'
  movies = CSV.read('/Users/eduardogutierrez/Desktop/Actualize/cap_stone/mood_flix_app/app/assets/datasets/imdb_movies.csv')
  # p movies[1]
  p movies.count
  titles = []
  summaries = []
  movies.each do |movie|
    if movie[0] != 'imdb_title_id'
      call_entity(movie[13])
      @title_entities.each do |entity|
        new_entity = Entity.create!(
          title_id: movie[0], 
          entity_name: entity[:name],
          entity_type: entity[:type]
        )
        p new_entity
      end
    end
  end
  p titles.count
  p summaries[0]

end

imdb_dataset()
