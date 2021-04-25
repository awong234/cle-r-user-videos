# This script uses the data in output/ to create content files for the Hugo site

# Setup ------------------------------------------------------------------------

library("yaml")

output <- c(
    "output/meetup_api_data.RDS",
    "output/youtube_api_data_unmatched.RDS",
    "output/youtube_videos_with_matches.RDS"
)
if (!all(file.exists(output))) {
    stop("Run scripts/get_video_list.R first to create output/")
}

hugoDir <- "content/"
dir.create(hugoDir, showWarnings = FALSE)

# Meetups ----------------------------------------------------------------------

meetupDir <- file.path(hugoDir, "meetups")
dir.create(meetupDir, showWarnings = FALSE, recursive = TRUE)

meetups <- readRDS("output/meetup_api_data.RDS")

for (i in 1:nrow(meetups)) {
    date <- as.character(meetups[i, "meetup_date"])
    id <- basename(meetups[i, "meetup_link"])
    title <- meetups[i, "meetup_name"]
    description <- meetups[i, "meetup_desc"]
    outfile <- file.path(meetupDir, paste0(date, ".md"))
    header <- list(
        date = date,
        id = id,
        title = title,
        description = description
    )
    cat(c("---\n", as.yaml(header, unicode = FALSE), "---\n"), file = outfile, sep = "")
}

# Videos -----------------------------------------------------------------------

videoDir <- file.path(hugoDir, "videos")
dir.create(videoDir, showWarnings = FALSE, recursive = TRUE)

videos <- readRDS("output/youtube_api_data_unmatched.RDS")

for (i in 1:nrow(videos)) {
    date <- as.character(videos[i, "youtube_publish_time"])
    id <- basename(videos[i, "youtube_video_id"])
    title <- videos[i, "youtube_title"]
    outfile <- file.path(videoDir, paste0(id, ".md"))
    header <- list(
        date = date,
        id = id,
        title = title
    )
    cat(c("---\n", as.yaml(header), "---\n"), file = outfile, sep = "")
}

# Add videos to meetups --------------------------------------------------------

matches <- readRDS("output/youtube_videos_with_matches.RDS")
matchesPerMeetup <- tapply(matches$youtube_video_id, matches$meetup_date, identity)

for (i in seq_along(matchesPerMeetup)) {
    meetup <- names(matchesPerMeetup)[i]
    meetupVideos <- matchesPerMeetup[[i]]
    outfile <- file.path(meetupDir, paste0(meetup, ".md"))
    meetupYaml <- read_yaml(outfile)

    # Handle yaml quirks so that "videos" field is always formatted as a list
    if (length(meetupVideos) > 1) {
        meetupYaml$videos <- meetupVideos
    } else {
        meetupYaml$videos <- list(meetupVideos)
    }

    cat(c("---\n", as.yaml(meetupYaml, unicode = FALSE), "---\n"), file = outfile, sep = "")
}
