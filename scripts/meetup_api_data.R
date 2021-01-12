# Setup ------------------------------------------------------------------------

source('libraries.R')
source('R/functions.R')

# Meetup API; get past events --------------------------------------------------

meetup_data = get_meetup_metadata()
