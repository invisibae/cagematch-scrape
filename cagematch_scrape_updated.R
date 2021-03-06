library(rvest)
library(tidyverse)
library(dplyr)
library(tidyr)
library(knitr)
library(tibbletime)
library(lubridate)
library(parallel)
library(MASS)
library(foreach)
library(doParallel)
library(readxl)


# Started off by defining functions that are going to grab things from a page linked to our original page 
# in this case, promotion (i.e. wrestling company), event (what show a match took place at), and match participants

get_promotion <- function(match_link) {
  match_page = read_html(url(match_link))
  match_promotion = match_page %>%
    html_nodes(".InformationBoxRow:nth-child(3) a") %>%
    html_text() 
  return(match_promotion)
}



get_event<- function(match_link) {
  match_page = read_html(url(match_link))
  match_event = match_page %>%
    html_nodes(".InformationBoxRow:nth-child(6) a:nth-child(1)") %>%
    html_text() 
  return(match_event)
}

get_participants = function(match_link) {
  match_page = read_html(url(match_link))
  match_event = match_page %>%
    html_nodes(".MatchResults a") %>%
    html_text() 
}

# what will eventually be our final dataframe "cagematch" is defined first as empty to be filled later 

cagematch <- data.frame()

# get page function to sweep for these elements on every page 
# turn the for looop into a function of its own


page_result <- seq(from = 0, to = 47700, by = 100)

run_the_entire_thing = function(page_result) {
  link <- paste0("https://www.cagematch.net/?id=111&view=list&s=0&sortby=colRating&sorttype=DESC&s=", 
                 page_result)
  
  page <- read_html(url(link))
  #match date node 
  date <- page %>% 
    html_nodes(".TextLowlight+ .TColSeparator") %>%
    html_text()
  
  # match node 
  match <- page %>% 
    html_nodes(".TCol:nth-child(4)") %>%
    html_text()
  # link to match detail page  
  match_links <- page %>% 
    html_nodes(".TCol:nth-child(4)") %>%
    html_nodes("a") %>%
    html_attr("href") %>% 
    paste("https://www.cagematch.net/", ., sep="")
  # Wrestling Observer Newsletter Score (Dave Meltzer)  
  WON <- page %>% 
    html_nodes(".TCol:nth-child(5)") %>%
    html_text()
  # type of match  
  type <- page %>% 
    html_nodes(".TCol:nth-child(6)") %>%
    html_text()
  # community rating  
  rating <- page %>% 
    html_nodes(".TCol:nth-child(7)") %>%
    html_text()
  # promotion is defined as a vector created by running the "get_promotion" function I created above  
  promotion <- sapply(match_links, FUN = get_promotion, USE.NAMES = FALSE)
  # ditto with event  
  event = sapply(match_links, FUN = get_event, USE.NAMES = FALSE)
  event[lengths(event) == 0] <- NA_character_ 
  event <- unlist(event)
  # double ditto with participants  
  participants <-sapply(match_links, FUN = get_participants, simplify = "vector", USE.NAMES = F) %>%
    sapply(toString)
  
  # and our final dataframe is just an rbind of individual elements on the page   
  cagematch <- rbind(cagematch, data.frame(date, match, WON, type, rating, promotion, event, participants, stringsAsFactors = F))
  # cagematch %>% write_rds
  print(paste("page:", page_result))
  
  #write to rds
  cagematch_name <- paste0("")
  
}




for(page_result in seq(from = 0, to = 47700, by = 100)) {
  link <- paste0("https://www.cagematch.net/?id=111&view=list&s=0&sortby=colRating&sorttype=DESC&s=", 
                 page_result)
  
  page <- read_html(url(link))
  #match date node 
  date <- page %>% 
    html_nodes(".TextLowlight+ .TColSeparator") %>%
    html_text()
  
  # match node 
  match <- page %>% 
    html_nodes(".TCol:nth-child(4)") %>%
    html_text()
  # link to match detail page  
  match_links <- page %>% 
    html_nodes(".TCol:nth-child(4)") %>%
    html_nodes("a") %>%
    html_attr("href") %>% 
    paste("https://www.cagematch.net/", ., sep="")
  # Wrestling Observer Newsletter Score (Dave Meltzer)  
  WON <- page %>% 
    html_nodes(".TCol:nth-child(5)") %>%
    html_text()
  # type of match  
  type <- page %>% 
    html_nodes(".TCol:nth-child(6)") %>%
    html_text()
  # community rating  
  rating <- page %>% 
    html_nodes(".TCol:nth-child(7)") %>%
    html_text()
  # promotion is defined as a vector created by running the "get_promotion" function I created above  
  promotion <- sapply(match_links, FUN = get_promotion, USE.NAMES = FALSE)
  # ditto with event  
  event = sapply(match_links, FUN = get_event, USE.NAMES = FALSE)
  event[lengths(event) == 0] <- NA_character_ 
  event <- unlist(event)
  # double ditto with participants  
  participants <-sapply(match_links, FUN = get_participants, simplify = "vector", USE.NAMES = F) %>%
    sapply(toString)
  
  # and our final dataframe is just an rbind of individual elements on the page   
  cagematch <- rbind(cagematch, data.frame(date, match, WON, type, rating, promotion, event, participants, stringsAsFactors = F))
  # cagematch %>% write_rds
  print(paste("page:", page_result))
  
}

# sapply(match_links, FUN = get_promotion, USE.NAMES = FALSE)


### from here it's all making things easier to read and transform





cagematch$rating <- cagematch$rating %>%
  as.double()


cagematch$WON[cagematch$WON==""] <- NA

cagematch$WON_number <- cagematch$WON %>%
  str_replace_all(c(
    '\\*\\*\\*\\*\\*\\*\\*' = "7",
    '\\*\\*\\*\\*\\*\\*' = "6",
    '\\*\\*\\*\\*\\*' = "5",
    '\\*\\*\\*\\*' = "4", 
    '\\*\\*\\*' = "3",
    '\\*\\*' = "2",
    '\\*' = "1",
    "1/4" = ".25", 
    "1/2" = ".5", 
    "3/4" = ".75"))

cagematch$WON <- as.double(cagematch$WON)


cagematch$date

cagematch$date <- cagematch$date %>%
  parse_date("%d.%m.%Y")

cagematch$date <- cagematch$date %>%
  as.Date()

cagematch %>%
  tbl_time(date) %>%
  arrange(date) %>%
  filter_time("2020" ~ "2020") %>%
  group_by(promotion) %>%
  summarise(avg_rating =mean(rating),
            avg_WON = mean(WON, na.rm = T),
            count = n()) %>%
  filter(count > 3) %>%
  arrange(desc(avg_rating)) %>%
  View()

cagematch %>%
  group_by(date) %>%
  summarise(rating = mean(rating),
            won = mean(WON , na.rm = T),
            count = n()) %>%
  filter(count > 8) %>%
  arrange(desc(rating))

cagematch



write_csv(cagematch, "cagematch.csv")

cagematch %>%
  group_by(promotion) %>%
  summarise(rating = mean(rating, na.rm = T),
            won = mean(WON , na.rm = T),
            count = n()) %>%
  filter(!is.na(rating) & !is.na(won), count > 100) %>%
  arrange(desc(rating)) %>%
  View()

cagematch
