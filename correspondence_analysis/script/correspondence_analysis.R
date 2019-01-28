setwd("C:/Users/traveler/Desktop/Jim/# R/# analytics/visual/correspondence_analysis/ver2")
# see # https://www.displayr.com/3d-correspondence-analysis-plots-in-r-using-plotly/?utm_medium=Feed&utm_source=Syndication

library(readxl)
library(tidyverse)
library(plotly)
library(plyr)

devtools::install_github("Displayr/flipDimensionReduction")
library(flipDimensionReduction)

# import
df <- readxl::read_excel("experiment_summary_9.26.2018.xlsx", sheet = "combined")
head(df)
names(df)

# remove " prior| forward" from the timeline column
df$timeline <- gsub(pattern = " prior| forward", replacement = "", df$timeline)

# spread from "long" to "wide" - easier to visualize in Excel (heatmap like visualization)
df.spread <- df %>%
        select(timeline, topic, odds, keyword, method, topic_source, user_extract_from, level) %>%
        tidyr::spread(key = timeline, value = odds) %>%
        # rearrange output columns order
        select(keyword, 
               method, 
               topic_source, 
               user_extract_from, 
               level, 
               topic, 
               `within 14-day`, 
               `15-to-21 day`, 
               `22-to-28 day`, 
               `29-to-35 day`, 
               `36-to-42 day`, 
               `43-to-63 day`, 
               `64-day or more`) %>%
        arrange(keyword, method, topic_source, user_extract_from, level, topic)

write.csv(df.spread, "df.spread_pivot.csv", row.names = F, append = F)

###############################################
##### scale the data.frame for each combo #####
###############################################

# the combos coming from the first five columns, i.e. [1] "keyword"           "method"            "topic_source"      "user_extract_from" "level" 
eg <- df.spread[, 1:5] %>%
        unique %>%
        as.data.frame %>%
        # arrange them in order before assigning a row id, so that it's easier to read and track
        arrange(keyword, method, topic_source, user_extract_from, level) %>%
        mutate(id = 1:nrow(eg))

# create an empty list for storing each df
ml <- vector(length = nrow(eg),  mode = "list")

# create an extractor function to extract each df
extractor <- function(x, y, z){
        df <- x %>%
                dplyr::filter(x$keyword == y$keyword[z] &
                               x$method == y$method[z] &
                               x$topic_source == y$topic_source[z] &
                              x$user_extract_from == y$user_extract_from[z] &
                              x$level == y$level[z]) %>%
                as.data.frame
}

# create a for-loop to loop through the original df and then extract each sub-part/combo
for(i in 1:nrow(eg)){
        
        z <- 1:nrow(eg)
        ml[[i]] <- extractor(x = df.spread, y = eg, z = z[i])
        
}

names(ml) <- eg$id
names(ml)

# test <- df.spread %>%
#         dplyr::filter(df.spread$keyword == eg$keyword[7] &
#                               df.spread$method == eg$method[7] &
#                               df.spread$topic_type == eg$topic_type[7] &
#                               df.spread$user_extract_from == eg$user_extract_from[7] &
#                               df.spread$level == eg$level[7]) %>%
#         as.data.frame
# 
# test[sapply(test, is.numeric)] <- lapply(test[sapply(test, is.numeric)], scale)

# scaling each numeric column in each df from the list
ml <- map(1:length(ml), function(x){
        ml[[x]][sapply(ml[[x]], is.numeric)] <- lapply(ml[[x]][sapply(ml[[x]], is.numeric)], scale)
        ml[[x]]
})

str(ml)

# put them back in one df before exporting
df.spread.scaled <- plyr::ldply(ml, data.frame) %>%
        arrange(keyword, method, topic_source, user_extract_from, level, topic)
names(df.spread.scaled) <- names(df.spread)        

write.csv(df.spread.scaled, "df.spread_pivot_scaled.csv", row.names = F, append = F)

######################################################################
################################################
# extract only top/most relevant topics based on recency, i.e. "within 14-day forward"
k = 'alternative-investments'
m = 'forward'
t = 'topic (bloomberg, >2)'

# cannot use the scaled df
df.spread_top <- df.spread %>%
        dplyr::filter(keyword == k & method == m & topic_source == t & `within 14-day` > 1.2) %>%
        select(topic, 
               `within 14-day`, 
               `15-to-21 day`, 
               `22-to-28 day`, 
               `29-to-35 day`, 
               `36-to-42 day`, 
               `43-to-63 day`) %>%
               # `64-day or more`) %>%
        mutate_all(funs(replace(., is.na(.), 0))) %>%
        arrange(desc(`within 14-day`)) %>%  
        head(20) %>%
        as.matrix 

################
###### 2d ######
################
my.ca <- flipDimensionReduction::CorrespondenceAnalysis(df.spread_top, 
                                                        normalization = "Column principal (scaled)")
my.ca

################
###### 3d ######
################
rc = my.ca$row.coordinates
cc = my.ca$column.coordinates
library(plotly)
p = plot_ly() 
p = add_trace(p, x = rc[,1], y = rc[,2], z = rc[,3],
              mode = 'text', text = rownames(rc),
              textfont = list(color = "red"), showlegend = FALSE) 
p = add_trace(p, x = cc[,1], y = cc[,2], z = cc[,3], 
              mode = "text", text = rownames(cc), 
              textfont = list(color = "blue"), showlegend = FALSE) 
p <- config(p, displayModeBar = FALSE)
p <- layout(p, scene = list(xaxis = list(title = colnames(rc)[1]),
                            yaxis = list(title = colnames(rc)[2]),
                            zaxis = list(title = colnames(rc)[3]),
                            aspectmode = "data"),
            margin = list(l = 0, r = 0, b = 0, t = 0))
p$sizingPolicy$browser$padding <- 0
my.3d.plot = p
my.3d.plot
