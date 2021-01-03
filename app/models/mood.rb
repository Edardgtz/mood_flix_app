class Mood < ApplicationRecord
  def get_genre_titles
    request_api("https://imdb8.p.rapidapi.com/title/get-popular-movies-by-genre?genre=comedy")
    @title_ids = []
    i = 0
    while i < @details.length
      titles_split = @details[i].split ('/') 
      @title_ids << titles_split[2]
      i += 1
    end
  end
end
