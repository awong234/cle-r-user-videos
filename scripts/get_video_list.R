# Setup ------------------------------------------------------------------------

source('libraries.R')
source('R/functions.R')

# Make output dir
if (! dir.exists(here::here('output'))) dir.create(here::here('output'))

# Memoise so as to avoid repetitive API calls when not required
get_youtube_videos_list = memoise::memoise(f = get_youtube_videos_list, cache = memoise::cache_filesystem(path = 'cache'))

# Data pull --------------------------------------------------------------------

# Meetup

meetup_data = get_meetup_metadata() %>% filter(names != 'Virtual R Café')

# Youtube

rusergroup_channel_id = URLencode('UC7C4YZ-9itQW7Nl4RVKDflg', reserved = TRUE)
key = Sys.getenv("APIKEY")
parts = c('snippet,id')
baseurl = sprintf('https://www.googleapis.com/youtube/v3/search?key=%s&channelId=%s&part=%s',
              key,
              rusergroup_channel_id,
              parts)

youtube_vids = get_youtube_videos_list(baseurl)

# Merge data -- the names are similar but not exact. Monogram and bigram matching should do the trick.

meetup_onegrams = tokenize_ngrams(meetup_data$names, n = 1, lowercase = TRUE, stopwords = c(stop_words$word))
meetup_bigrams = tokenize_ngrams(meetup_data$names, n = 2, lowercase = TRUE)
youtube_onegrams = tokenize_ngrams(youtube_vids$titles, n = 1, lowercase = TRUE, stopwords = c(stop_words$word))
youtube_bigrams = tokenize_ngrams(youtube_vids$titles, n = 1, lowercase = TRUE, stopwords = c(stop_words$word))

meetup_matches = vector(mode = 'integer', length = length(meetup_onegrams))
matchorder = cross2(meetup_data$names, youtube_vids$titles)
meetup_index = map_int(matchorder, ~match(.x[[1]], meetup_data$names))
matchlist_1 = cross2(meetup_onegrams, youtube_onegrams)
matchlist_2 = cross2(meetup_bigrams, youtube_bigrams)
tmp1 = map_int(matchlist_1, function(x) {
    meetup_grams = x[[1]]
    youtube_grams = x[[2]]
    meetup_matches = rep(0, length(meetup_grams))
    for (i in meetup_grams) {
        meetup_matches[i] = sum(i == youtube_grams) %>% as.integer()
    }
    return(as.integer(sum(meetup_matches)))
})

tmp2 = map_int(matchlist_2, function(x) {
    meetup_grams = x[[1]]
    youtube_grams = x[[2]]
    meetup_matches = rep(0, length(meetup_grams))
    for (i in meetup_grams) {
        meetup_matches[i] = sum(i == youtube_grams)
    }
    out = as.integer(sum(meetup_matches))
    return(out)
})

matchvalues = (tmp1 + tmp2)

# For each meetup desc, take the greatest number
maxmatches = vector(mode = integer, length = nrow(meetup_data))
for (i in seq_along(meetup_matches)) {
    message(meetup_data$names[i])
    ind = which(meetup_index == i)
    this_meetup = matchorder[ind]
    this_matches = matchvalues[ind]
    best_match_ind = ind[which.max(this_matches)]
    print(matchorder[best_match_ind])
}

