# Setup ------------------------------------------------------------------------

library(dplyr)
library(xml2)
library(jsonlite)
library(purrr)


# Youtube API -- get the videos ------------------------------------------------

rusergroup_channel_id = URLencode('UC7C4YZ-9itQW7Nl4RVKDflg', reserved = TRUE)
key = Sys.getenv("APIKEY")

format_response = function(url) {
    read_html(url) %>%
        xml2::xml_find_all('//text()') %>%
        as.character() %>%
        parse_json()
}

get_videos_list = function(baseurl) {
    get_item_detail = function(resp, detail) {
        out = map(resp$items, ~.x[[detail]])
        out[sapply(out, is.null)] = NA_character_
        out = do.call(c, out)
        return(out)
    }
    resp          = format_response(url)
    titles        = get_item_detail(resp, c('snippet', 'title'))
    publish_times = get_item_detail(resp, c('snippet', 'publishTime'))
    video_ids     = get_item_detail(resp, c('id', 'videoId'))
    kinds         = get_item_detail(resp, c('id', 'kind'))
    while(!is.null(resp$nextPageToken)) {
        nextToken     = resp$nextPageToken
        modify_url    = paste0(url, sprintf("&pageToken=%s", nextToken))
        resp          = format_response(modify_url)
        titles        = c(titles, get_item_detail(resp, c('snippet', 'title')))
        publish_times = c(publish_times, get_item_detail(resp, c('snippet', 'publishTime')))
        video_ids     = c(video_ids, get_item_detail(resp, c('id', 'videoId')))
        kinds         = c(kinds, get_item_detail(resp, c('id', 'kind')))
    }
    df = data.frame(
        titles        = titles,
        publish_times = publish_times,
        video_ids     = video_ids
    )
    video_links = paste0('http://www.youtube.com/watch?v=', video_ids)
    df$links = video_links
    # keep only the videos
    df = df[kinds == 'youtube#video', ]

    return(df)
}

parts = c('snippet,id')
url = sprintf('https://www.googleapis.com/youtube/v3/search?key=%s&channelId=%s&part=%s',
              key,
              rusergroup_channel_id,
              parts)

videos = get_videos_list(url)
