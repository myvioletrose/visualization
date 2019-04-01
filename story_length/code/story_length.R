setwd("C:/Users/traveler/Desktop/story_length/code")
current_wd <- getwd()

# load packages
library(tidyverse)
library(wrapr)
library(Hmisc)
library(readit)
library(plyr)
library(corrplot)
library(plotly)
library(htmlwidgets)
library(gridExtra)

setwd("../"); setwd("data")
df <- readit("adhoc_story_pub_2019.csv")
df2 <- readit("output_combined.xlsx")

# extract body, clean and then count word from "html" document
extract <- function(body, word_count = T){
        b <- str_extract_all(body,
                             # pattern = "(<p>|<p id=).+?</p>") %>% 
                             pattern = "(<p>|<p data-type=|<p id=|<li>).+?(</p>|</li>)") %>%
                unlist %>%
                paste(., collapse="") %>%
                # gsub("<a.+?</a>|<p>|</p>", "", .) %>%
                # gsub("<figure.+?</figure>", "", .) %>%
                # gsub("<ul>|</ul>|<li>|</li>", "", .) %>%
                gsub("<.+?>", "", .) %>%
                gsub("&amp;", "&", .) %>%
                gsub("&quot;", "\"", .) %>%
                gsub("&apos;", "\'", .) %>%
                gsub("\\\\", "", .) %>%
                gsub("&lt;", "<", .) %>%
                gsub("&gt;", ">", .) 
        
        wc <- b %>% str_count(., '\\w+')
        
        if(word_count == T){
                return(wc)
        } else {
                return(b)
        }
}

# use possibly to handle error, e.g. some story_ids either not have body or messy html
possibly_extract <- possibly(extract, otherwise = NA_real_)

################################
#########
# check # 
#########
# # test
# test <- head(df)
# testOutput <- test %>%
#         dplyr::mutate(word_count = purrr::map(body, 
#                                               function(x) possibly_extract(x, word_count = T))%>% unlist,
#                       body = purrr::map(body, 
#                                         function(x) possibly_extract(x, word_count = F)))
# 
# # word count
# df %>%
#         dplyr::filter(id == "PNWKN56JTSE801") %>%
#         dplyr::select(body) %>%
#         possibly_extract(.)
# 
# # body
# df %>% 
#         dplyr::filter(id == "PNWR3R6KLVR401") %>%
#         dplyr::select(body) %>%
#         possibly_extract(., word_count = F)

############################################################
# count word, extract body 
system.time(
dfOutput <- df %>%
        dplyr::mutate(word_count = purrr::map(body, 
                                              function(x) possibly_extract(x, word_count = T))%>% unlist,
                      body = purrr::map(body, 
                                        function(x) possibly_extract(x, word_count = F)))
)

# write output
# write.csv(dfOutput, "dfOutput.csv", row.names = F)

# merge dfOutput, df2 together
combined <- dplyr::inner_join(df2, dfOutput, by = "id")

# clean-up
combined <- combined %>%
        dplyr::mutate(avg_time_on_page = lubridate::minute(avg_time_on_page) * 60 
                      + lubridate::second(avg_time_on_page))

######################################################
############## EDA
#############################
# set wd
setwd("../"); setwd("plot")

windows()

# time spent on reading vs pvs
combined %>%
        dplyr::select(pvs, avg_time_on_page) %>%
        dplyr::mutate(time_break = cut(combined$avg_time_on_page, 
                                             breaks = c(0, 60, 120, 180, 240, 300, 1200))) %>%
        boxplot(.$pvs ~ .$time_break, .)

cut(combined$avg_time_on_page, breaks = c(0, 60, 120, 180, 240, 300, 1200)) %>% table

# corrplot
combined %>%
        dplyr::filter(type == "article") %>%
        dplyr::select(pvs, word_count, avg_time_on_page) %>%
        cor() %>%
        corrplot.mixed(.,
                       # lower.col = "black", 
                       number.cex = .8)
        # corrplot(., 
        #          # method = "circle"
        #          method = "number")

# density chart - distribution of word by channel
combined %>% dplyr::select(primary_site, pvs) %>% 
        ggplot(., aes(pvs, fill = primary_site)) +
        geom_density(alpha = 0.1) +
        facet_wrap(~ primary_site, "free_y")

# distribution of words
# by brand
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(primary_site, word_count) %>% 
        # dplyr::filter(word_count <= 3000) %>%
        # ggplot(., aes(word_count, fill = primary_site)) +
        ggplot(., aes(word_count)) +
        # geom_density(position = "stack", alpha = 0.5) + 
        geom_density(alpha = 0.5) + 
        ggtitle("Articles published in 2019: Word Count Distribution") + 
        theme_bw()

# all at once, by avg read time
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(word_count, avg_time_on_page) %>% 
        dplyr::mutate(avg_read_time = cut(avg_time_on_page, 
                                          breaks = c(0, 60, 120, 180, 240, 300, 1200), 
                                          labels = c("under 1 min", "1 to 2 min", "2 to 3 min", 
                                                     "3 to 4 min", "4 to 5 min", "5 min or more"))) %>%
        dplyr::filter(avg_read_time != is.na(avg_read_time)) %>%
        # dplyr::filter(word_count <= 3000) %>%
        ggplot(., aes(word_count, fill = avg_read_time)) +
        # geom_density(position = "stack", alpha = 0.5) + 
        geom_density(alpha = 0.5) + 
        theme_bw() + 
        theme(legend.position = "none", plot.title = element_text(hjust = 0.5)) +
        ggtitle("Articles published in 2019: Word Count Distribution by Avg Reading Time") + 
        facet_wrap(~ avg_read_time, ncol = 3)


##########################################
### word count vs. pvs ###
# ver1
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(primary_site, word_count, pvs, avg_time_on_page) %>%
        dplyr::mutate(avg_read_time = cut(avg_time_on_page, 
                                       breaks = c(0, 60, 120, 180, 240, 300, 1200), 
                                       labels = c("under 1 min", "1 to 2 min", "2 to 3 min", 
                                                  "3 to 4 min", "4 to 5 min", "5 min or more"))) %>%
        dplyr::filter(avg_read_time != is.na(avg_read_time)) %>%
        # dplyr::filter(word_count <= 1500) %>%
        ggplot(., aes(x = word_count, y = pvs / 1000)) +
        labs(x = "word count", y = "pvs ('000)") +
        theme(legend.position = "top", plot.title = element_text(hjust = 0.5)) +
        ggtitle("Articles published in 2019: Word Count vs Page Views (in '000) by Brands") + 
        geom_point(aes(col = avg_read_time, shape = avg_read_time)) + 
        geom_smooth(method = "lm", se = T, size = 0.5, color = "deepskyblue4", linetype = 2) + 
        facet_wrap(~ primary_site, "free_y", ncol = 3) -> scatterPlot

# Save it locally
plotly::ggplotly(scatterPlot, tooltip = "text") -> p  # tooltip
htmlwidgets::saveWidget(as_widget(p), "word_count.html")

##########################################
# ver2
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(primary_site, word_count, pvs, avg_time_on_page) %>%
        dplyr::mutate(avg_read_time = cut(avg_time_on_page, 
                                          breaks = c(0, 60, 120, 180, 240, 300, 1200), 
                                          labels = c("under 1 min", "1 to 2 min", "2 to 3 min", 
                                                     "3 to 4 min", "4 to 5 min", "5 min or more"))) %>%
        dplyr::filter(avg_read_time != is.na(avg_read_time)) %>%
        # dplyr::filter(word_count <= 1500) %>%
        ggplot(., aes(x = word_count, y = pvs / 1000)) +
        labs(x = "word count", y = "pvs ('000)") +
        theme(legend.position = "top", plot.title = element_text(hjust = 0.5)) +
        ggtitle("Articles published in 2019: Word Count vs Page Views (in '000)") + 
        geom_point(aes(col = avg_read_time, shape = avg_read_time)) + 
        geom_smooth(method = "lm", se = T, size = 0.5, 
                    color = "deepskyblue4", linetype = 2) -> scatterPlot2

# Save it locally
plotly::ggplotly(scatterPlot2, tooltip = "text") -> p  # tooltip
htmlwidgets::saveWidget(as_widget(p), "word_count2.html")

#########################################################
# 2-D charts
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(word_count, pvs, avg_time_on_page) %>%
        ggplot(., aes(x = word_count, y = pvs / 1000)) +
        labs(x = "word count", y = "pvs ('000)") +
        theme(legend.position = "none", plot.title = element_text(hjust = 0.5)) +
        ggtitle("Articles published in 2019: Word Count vs Page Views (in '000)") + 
        geom_point() +
        geom_smooth(method = "lm", se = T, size = 0.5, 
                    color = "deepskyblue4", linetype = 2) -> chart1

combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(word_count, pvs, avg_time_on_page) %>%
        ggplot(., aes(x = word_count, y = avg_time_on_page)) +
        labs(x = "word count", y = "avg read time (in seconds)") +
        theme(legend.position = "none", plot.title = element_text(hjust = 0.5)) +
        ggtitle("Articles published in 2019: Word Count vs Avg Read time (in seconds)") + 
        geom_point() +
        geom_smooth(method = "lm", se = T, size = 0.5, 
                    color = "deepskyblue4", linetype = 2) -> chart2

grid.arrange(chart1, chart2, ncol = 2)



#####################
# word count bucket 
# pvs
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(word_count) %>%
        dplyr::mutate(word_count = 
        cut(word_count, 
            breaks = c(0, 500, 1000, 1500, 2000, 2500, 6000),
            labels = c("less than 500", "500 to 1000", "1000 to 1500", 
                       "1500 to 2000", "2000 to 2500", "2500 or more")) 
        ) %>%
        ftable

# distribution of pvs
# by word_count bucket
combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(pvs, word_count) %>% 
        dplyr::mutate(word_count = 
                              cut(word_count, 
                                  breaks = c(0, 500, 1000, 1500, 2000, 2500, 6000),
                                  labels = c("less than 500", "500 to 1000", "1000 to 1500", 
                                             "1500 to 2000", "2000 to 2500", "2500 or more")) 
        ) %>%
        # dplyr::filter(word_count <= 3000) %>%
        # ggplot(., aes(word_count, fill = primary_site)) +
        ggplot(., aes(pvs / 1000, fill = word_count)) +
        # geom_density(position = "stack", alpha = 0.5) + 
        geom_density(alpha = 0.5) +
        labs(x = "pvs (in '000)") + 
        ggtitle("Articles published in 2019: Page Views Distribution by Word Count") + 
        theme_bw() + 
        facet_wrap(~ word_count, ncol = 3, scales = "free")

break1 <- c(0, 500, 1000, 1500, 2000, 2500, 6000)
label1 <- c("less than 500", "500 to 1000", "1000 to 1500", 
            "1500 to 2000", "2000 to 2500", "2500 or more")

break2 <- c(0, 500, 1000, 1500, 6000)
label2 <- c("less than 500", "500 to 1000", "1000 to 1500", "1500 or more")

combined %>% dplyr::filter(type == "article") %>%
        dplyr::select(word_count, pvs) %>%
        dplyr::mutate(word_count = 
                              cut(word_count, 
                                  breaks = break2,
                                  labels = label2)
        ) %>% 
        group_by(word_count) %>%
        summarise(sum_pvs = sum(pvs),
                  articles = n(),
                  avg_pvs = mean(pvs),
                  med_pvs = median(pvs))

####################################
# reset wd
setwd(current_wd)


