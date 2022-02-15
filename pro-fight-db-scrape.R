library(rvest)
library(Hmisc)
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
library(purrr)

# Table that iterates between pages ---------------------------------------

x <- seq(from = 1, to = 37, by = 1)
urls <- paste0('http://www.profightdb.com/cards/aew-cards-pg',x,'-no-285.html?order=&type=')



get_table <- function(url) {
  urls %>%
    read_html() %>%
    html_nodes(xpath ='/html/body/div/div[1]/div[3]/div[2]/div[3]/div/div/table') %>%
    html_table()
}

results <- sapply(urls, get_table)

table_of_lists <- bind_rows(results, .id = "column_label") 

table_of_lists %>%
  View()


# let's try to write functions to grab individual nodes off a page 

page <- read_html(url(urls))

match_links <- page %>% 
  html_nodes(".TCol:nth-child(4)") %>%
  html_nodes("a") %>%
  html_attr("href") %>% 
  paste("https://www.cagematch.net/", ., sep="")

get_participants = function(match_link) {
  match_page = read_html(url(match_link))
  match_event = match_page %>%
    html_nodes(".MatchResults a") %>%
    html_text() 
}



