# Setup ------------------------------------------------------------------------

library(dplyr)
library(xml2)
library(jsonlite)
library(purrr)

source('R/functions.R')

rusergroup_channel_id = URLencode('UC7C4YZ-9itQW7Nl4RVKDflg', reserved = TRUE)
key = Sys.getenv("APIKEY")

# Youtube API -- get the videos ------------------------------------------------

parts = c('snippet,id')
url = sprintf('https://www.googleapis.com/youtube/v3/search?key=%s&channelId=%s&part=%s',
              key,
              rusergroup_channel_id,
              parts)

videos = get_videos_list(url)
