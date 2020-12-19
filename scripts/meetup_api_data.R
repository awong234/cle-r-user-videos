library(jsonlite)
library(dplyr)
library(rvest)

# Meetup API; get past events

url = "https://api.meetup.com/Cleveland-UseR-Group/events/?&status=past"

res = curl::curl_fetch_memory(url)
content = parse_json(rawToChar(res$content))
dates = lapply(content, function(x) x$local_date) %>% do.call(c, .) %>% as.Date()
names = lapply(content, function(x) x$name) %>% do.call(c, .)
links = lapply(content, function(x) x$link) %>% do.call(c, .)
desc  = lapply(content, function(x) {
    obj = xml2::read_html(x$description) %>%
        xml2::xml_find_all(xpath = '//p') %>%
        xml2::xml_text()
    obj = paste0(obj, collapse = '\n')
    return(obj)
})
desc = do.call(c, desc)

df = tibble(
    names,
    dates,
    links,
    desc
)

# Try to extract the author/presenter name from the description.
