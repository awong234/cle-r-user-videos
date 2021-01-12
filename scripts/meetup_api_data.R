# Setup ------------------------------------------------------------------------

library(jsonlite)
library(dplyr)
library(rvest)
library(keyring)
library(reticulate)

# Meetup API; get past events --------------------------------------------------

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

df = tibble(
    names,
    dates,
    links,
    desc
)

# Remove the cafe's
df = df %>%
    filter(names != 'Virtual R Café')
