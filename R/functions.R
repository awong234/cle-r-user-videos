
format_response = function(url) {
    read_html(url) %>%
        xml2::xml_find_all('//text()') %>%
        as.character() %>%
        parse_json()
}

get_meetup_metadata = function() {
    url = "https://api.meetup.com/Cleveland-UseR-Group/events/?&status=past"
    html = read_html(url)
    content = html %>%
        # Get the text out
        xml2::xml_find_all('//text()') %>%
        # Convert to character
        as.character() %>% paste0(collapse = '') %>%
        # Convert from character json to list
        parse_json()

    dates = lapply(content, function(x) x$local_date) %>% do.call(c, .) %>% as.Date()
    names = lapply(content, function(x) x$name) %>% do.call(c, .)
    links = lapply(content, function(x) x$link) %>% do.call(c, .)
    desc  = lapply(content, function(x) x$description) %>% do.call(c, .)

    meetup_info_df = tibble(
        names,
        dates,
        links,
        desc
    )

    # Remove the cafe's
    meetup_info_df = meetup_info_df %>%
        filter(names != 'Virtual R Café')

    return(meetup_info_df)
}

get_youtube_videos_list = function(url) {
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
