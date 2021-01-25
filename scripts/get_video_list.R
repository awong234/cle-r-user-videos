# Setup ------------------------------------------------------------------------

source('libraries.R')
source('R/functions.R')

# Make output dir
if (! dir.exists(here::here('output'))) dir.create(here::here('output'))

# Memoise so as to avoid repetitive API calls when not required
get_youtube_videos_list = memoise::memoise(f = get_youtube_videos_list, cache = memoise::cache_filesystem(path = 'cache'))

# Data pull --------------------------------------------------------------------

# Meetup

meetup_data = get_meetup_metadata() %>% filter(meetup_name != 'Virtual R Café') %>%
    mutate(meetup_date = as.Date(meetup_date))

saveRDS(meetup_data, file = 'output/meetup_api_data.RDS')

# Youtube

rusergroup_channel_id = URLencode('UC7C4YZ-9itQW7Nl4RVKDflg', reserved = TRUE)
key = Sys.getenv("APIKEY")
parts = c('snippet,id')
baseurl = sprintf('https://www.googleapis.com/youtube/v3/search?key=%s&channelId=%s&part=%s',
              key,
              rusergroup_channel_id,
              parts)

youtube_vids = get_youtube_videos_list(baseurl)

saveRDS(youtube_vids, file = 'output/youtube_api_data_unmatched.RDS')

# Youtube vid titles have the meetup dates; extract those

title_has_date = grepl(youtube_vids$youtube_title, pattern = "\\d+/\\d+/\\d{4}")

youtube_vids$meetup_date = NA

youtube_vids$meetup_date[title_has_date] = regmatches(
    x = youtube_vids$youtube_title,
    m = regexpr(text = youtube_vids$youtube_title, pattern = '\\d+/\\d+/\\d{4}', perl = TRUE)
)

youtube_vids$meetup_date = as.Date(youtube_vids$meetup_date, format = '%m/%d/%Y')

# Try to join by date first -- join in this order because there may be more than
# 1 vid per meetup, but never more than 1 meetup per vid

youtube_vids = youtube_vids %>%
    left_join(meetup_data, by = c('meetup_date'))

# For the remaining that have no match, attempt n-gram matching
matched_vids = youtube_vids %>% filter(! is.na(meetup_name))
nonmatched_vids = youtube_vids %>% filter(is.na(meetup_name))
nonmatched_meetups = anti_join(meetup_data, youtube_vids, by = c("meetup_name", "meetup_date"))

meetup_onegrams = tokenize_ngrams(nonmatched_meetups$meetup_name, n = 1, lowercase = TRUE, stopwords = c(stop_words$word))
meetup_bigrams = tokenize_ngrams(nonmatched_meetups$meetup_name, n = 2, lowercase = TRUE)
youtube_onegrams = tokenize_ngrams(nonmatched_vids$youtube_title, n = 1, lowercase = TRUE, stopwords = c(stop_words$word))
youtube_bigrams = tokenize_ngrams(nonmatched_vids$youtube_title, n = 1, lowercase = TRUE, stopwords = c(stop_words$word))

matchorder = cross2(nonmatched_meetups$meetup_name, nonmatched_vids$youtube_title)
meetup_index = map_int(matchorder, ~match(.x[[2]], nonmatched_vids$youtube_title))
matchlist_1 = cross2(meetup_onegrams, youtube_onegrams)
matchlist_2 = cross2(meetup_bigrams, youtube_bigrams)
monogram_matches = map_int(matchlist_1, function(x) {
    meetup_grams = x[[1]]
    youtube_grams = x[[2]]
    meetup_matches = rep(0, length(meetup_grams))
    for (i in meetup_grams) {
        meetup_matches[i] = sum(i == youtube_grams)
    }
    return(as.integer(sum(meetup_matches)))
})

bigram_matches = map_int(matchlist_2, function(x) {
    meetup_grams = x[[1]]
    youtube_grams = x[[2]]
    meetup_matches = rep(0, length(meetup_grams))
    for (i in meetup_grams) {
        meetup_matches[i] = sum(i == youtube_grams)
    }
    out = as.integer(sum(meetup_matches))
    return(out)
})

matchvalues = (monogram_matches + bigram_matches)

# For each video, take the max matching value and assume vid belongs to that one.
for (i in 1:nrow(nonmatched_vids)) {
    # message(nonmatched_vids$youtube_title[i], ", ",  i)
    ind = which(meetup_index == i)
    this_meetup = matchorder[ind]
    this_matches = matchvalues[ind]
    best_match_ind = ind[which.max(this_matches)]
    # print(matchorder[best_match_ind])
    this_youtube_title = matchorder[best_match_ind][[1]][[2]]
    this_data_row = nonmatched_vids$youtube_title == this_youtube_title
    matching_meetup_title = matchorder[best_match_ind][[1]][[1]]
    matching_meetup_ind = match(matching_meetup_title, nonmatched_meetups$meetup_name)
    matching_meetup_data = nonmatched_meetups[matching_meetup_ind, ]
    matching_meetup_data$youtube_title = this_youtube_title
    nonmatched_vids$meetup_name[this_data_row] = matching_meetup_data$meetup_name
    nonmatched_vids$meetup_date[this_data_row] = matching_meetup_data$meetup_date
    nonmatched_vids$meetup_link[this_data_row] = matching_meetup_data$meetup_link
    nonmatched_vids$meetup_desc[this_data_row] = matching_meetup_data$meetup_desc
}

youtube_vids = bind_rows(
    nonmatched_vids,
    matched_vids
)

saveRDS(youtube_vids, 'output/youtube_videos_with_matches.RDS')
# END
