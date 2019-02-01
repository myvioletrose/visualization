# the objective is to use dotplot for displaying Average Order Value (AOV) for each shipping country by a retail brand
# likewise, we can display AOV for each brand by shipping country
# say, there's a dataset that has only three columns, i.e. "brand", "country" and "aov"
# each brand can sell/ship products to different countries in the world
# we summarize the statistic and figure out the Average Order Value for each brand to each of their shipping countries
# such as "brand 1" AOV for Hong Kong is 224.4, whereas Israel is 130.8
# how can we visually group and display countries (or brands) with similar AOV (or other KPI) together?!
# we can create an advanced dotplot using ggplot2 and ggrepel to solve this question

# see this <- 'https://cran.r-project.org/web/packages/ggrepel/vignettes/ggrepel.html'

# load sample df
setwd("../"); setwd("data")
load("sample_df.rda")

# load libraries
library(dplyr)
library(ggrepel)
library(ggplot2)

#########################
######### brand #########
#########################
setwd("../"); setwd("figure")
if(any(dir() == "brand")){unlink("brand", recursive = T)} else {dir.create("brand")}; setwd("brand")

# split by brand
df_brand_split <- split(df, df$brand)

# for loop - build and save chart for each brand
for(i in 1:length(df_brand_split)){
        x <- ggplot(df_brand_split[[i]], 
                    aes(x = reorder(country, aov), y = aov)) +
                labs(x = "Country", y = "AOV") +
                geom_point(stat = "identity", color = 'grey', aes(fill = factor(aov))) + 
                coord_flip() +
                geom_label_repel(aes(country, aov, fill = factor(aov), label = country),
                                 size = 4, fontface = 'bold', color = 'white', 
                                 box.padding = unit(0.5, "lines"),
                                 point.padding = unit(0.5, "lines"), 
                                 segment.color = 'grey50', segment.size = 1.5,
                                 force = 5) +
                # only display AOV values above the median to avoid showing too many numbers in one chart
                geom_text_repel(aes(label = ifelse(aov > median(aov), aov, '')), 
                                size = 4, color = 'red',
                                force = 2) +
                theme(legend.position = "none", 
                      axis.text.x = element_text(angle = 60, hjust = 1),
                      plot.title = element_text(hjust = 0.5)) +
                ggtitle(paste(unique(df_brand_split[[i]]$brand), "AOV by Country", sep = " : "))
        
        ggsave(file = paste(unique(df_brand_split[[i]]$brand), "_country_AOV.png", sep = ""),
               x, width = 15, height = 12)        
}


###########################
######### country #########
###########################
setwd("../")
if(any(dir() == "country")){unlink("country", recursive = T)} else {dir.create("country")}; setwd("country")

# split by country
df_country_split <- split(df, df$country)

# for loop - build and save chart for each country
for(i in 1:length(df_country_split)){
        x <- ggplot(df_country_split[[i]], 
                    aes(x = reorder(brand, aov), y = aov)) +
                labs(x = "Brand", y = "AOV") +
                geom_point(stat = "identity", color = 'grey', aes(fill = factor(aov))) + 
                coord_flip() + 
                geom_label_repel(aes(brand, aov, fill = factor(aov), label = brand),
                                 size = 4, fontface = 'bold', color = 'white', 
                                 box.padding = unit(0.5, "lines"),
                                 point.padding = unit(0.5, "lines"), 
                                 segment.color = 'grey50', segment.size = 1.5,
                                 force = 5) +
                # only display AOV values above the median to avoid showing too many numbers in one chart
                geom_text_repel(aes(label = ifelse(aov > median(aov), aov, '')), 
                                size = 4, color = 'red',
                                force = 2) +
                theme(legend.position = "none", 
                      axis.text.x = element_text(angle = 60, hjust = 1),
                      plot.title = element_text(hjust = 0.5)) +
                ggtitle(paste(unique(df_country_split[[i]]$country), "AOV by Brand", sep = " : "))
        
        ggsave(file = paste(unique(df_country_split[[i]]$country), "_brand_AOV.png", sep = ""),
               x, width = 15, height = 12)        
}
