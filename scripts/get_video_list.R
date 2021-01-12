# Setup ------------------------------------------------------------------------

source('libraries.R')
source('R/functions.R')

# Data pull --------------------------------------------------------------------

# Meetup

meetup_data = get_meetup_metadata()

# Youtube

rusergroup_channel_id = URLencode('UC7C4YZ-9itQW7Nl4RVKDflg', reserved = TRUE)
key = Sys.getenv("APIKEY")
parts = c('snippet,id')
url = sprintf('https://www.googleapis.com/youtube/v3/search?key=%s&channelId=%s&part=%s',
              key,
              rusergroup_channel_id,
              parts)

youtube_vids = get_youtube_videos_list()

# Merge data
