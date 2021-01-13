# Setup ------------------------------------------------------------------------

source('libraries.R')
source('R/functions.R')

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

# Merge data -- the names are similar but not exact. Bigram matching should do the trick.

meetup_data_ngrams = meetup_data %>%
    mutate(names_mod = gsub(pattern = '\\d', replacement = '', x = names, perl = TRUE)) %>%
    tidytext::unnest_ngrams(output = 'ngram', input = names_mod, n = 2, format = 'text', to_lower = TRUE, stopwords = c(stop_words$word))

youtube_vids_ngrams = youtube_vids %>%
    mutate(titles_mod = gsub(pattern = '\\d', replacement = '', x = titles, perl = TRUE)) %>%
    tidytext::unnest_ngrams(output = 'ngram', input = titles_mod, n = 2, format = 'text', to_lower = TRUE, stopwords = c(stop_words$word))

meetup_data_ngrams_spl = meetup_data_ngrams %>% group_by(names) %>% group_split()
youtube_vids_ngrams_spl = youtube_vids_ngrams %>% group_by(video_ids) %>% group_split()

# For each ngram in the meetups, search the ngrams in the youtube vids, and tally matches
meetup_names = sapply(meetup_data_ngrams_spl, function(x) x$names[1])
youtube_titles = sapply(youtube_vids_ngrams_spl, function(x) x$titles[1])
vid_records = list()
for (v in seq_along(youtube_vids_ngrams_spl)) {
    ngrams = youtube_vids_ngrams_spl[[v]][['ngram']]
    meetup_matches = vector(mode = 'integer', length = length(meetup_names))
    names(meetup_matches) = meetup_names
    for (m in seq_along(meetup_data_ngrams_spl)) {
        meetup_ngrams = meetup_data_ngrams_spl[[m]][['ngram']]
        meetup_matches[m] = sapply(ngrams, function(x) x == meetup_ngrams) %>% sum
    }
    vid_records[[v]] = meetup_matches
}

vid_matches = sapply(vid_records, which.max)
tibble(
    youtube_title = youtube_titles,
    meetup_name   = meetup_names[vid_matches]
) %>% print(n=100)
