# Setup ------------------------------------------------------------------------

source('libraries.R')
source('R/functions.R')

# Memoise so as to avoid repetitive API calls when not required
get_youtube_videos_list = memoise::memoise(f = get_youtube_videos_list, cache = memoise::cache_filesystem(path = 'cache'))

# Data pull --------------------------------------------------------------------

# Meetup

meetup_data = get_meetup_metadata()

# Youtube

rusergroup_channel_id = URLencode('UC7C4YZ-9itQW7Nl4RVKDflg', reserved = TRUE)
key = Sys.getenv("APIKEY")
parts = c('snippet,id')
baseurl = sprintf('https://www.googleapis.com/youtube/v3/search?key=%s&channelId=%s&part=%s',
              key,
              rusergroup_channel_id,
              parts)

youtube_vids = get_youtube_videos_list(baseurl)

# Merge data
