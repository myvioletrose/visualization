# load packages
library(readxl)
library(plyr)
library(tidyverse)

# house keeping here
ls(pos = "package:readxl")        
dir()
df <- readxl::read_excel("feature_analysis.xlsx")
df <- df %>%
        mutate(flag = dplyr::if_else(odds > 1.2, 1, 0),
               label = paste0(value, " (uvs = ", test_yes, ")"))
plyr::count(df, "flag")
head(df)
dim(df)

# check min, max of uvs
purrr::map(list(min, max), function(x) {
        aggregate(test_yes ~ attribute,
                  data = df[df$flag == 1, ], 
                  FUN = x)
})

##############################################################################
############################### write function ###############################
##############################################################################
dumpChart <- function(df, 
                      attribute = "attribute", label = "label", value = "odds", 
                      threshold = 1.2, n = 10, 
                      foldername = "chart"){
        
        # set up
        old.dir <- getwd()
        dir.create(paste0(old.dir, "/", foldername))
        setwd(paste0(old.dir, "/", foldername))
        
        x <- rlang::enquo(attribute)
        y <- rlang::enquo(label)
        z <- rlang::enquo(value)
        threshold <- rlang::enquo(threshold)
        row <- eval(n)
        
        # extract function - clean and transform into list by attribute
        makeList <- function(df, x, y, z){
                library(plyr, quietly = T, warn.conflicts = T)
                library(dplyr, quietly = T, warn.conflicts = T)
                library(rlang, quietly = T, warn.conflicts = T)
                
                attributeList <- df %>%
                        dplyr::filter(odds > !!threshold) %>%
                        dplyr::select(!!x, !!y, !!z)
                names(attributeList) <- c("attribute", "label", "odds")
                attributeList <- attributeList %>%
                        dplyr::group_by(attribute) %>%
                        dplyr::arrange(desc(odds)) %>%
                        dplyr::top_n(row) 
                attributeList <- attributeList %>%
                        plyr::dlply(., "attribute")
                
                return(attributeList)
        }
        
        # create the list
        theList <- makeList(df, x, y, z)
        
        # customized bar chart function
        chart <- function(x) {
                ggplot(x, aes(x = reorder(label, odds), y = odds)) +
                        geom_bar(stat = "identity", fill = "deepskyblue3") +
                        coord_flip() +
                        labs(x = "", y = "odds") +
                        theme(text = element_text(size = 8)) + 
                        # ggtitle(paste0(unique(x$attribute), " (# uniques)")) +
                        geom_text(aes(x = label, y = odds, label = round(odds, 2)),
                                  position = position_dodge(width = 1), hjust = 1.5,
                                  col = "white", fontface = "bold", size = 2)
                
                ggsave(filename = paste0(unique(x$attribute), ".png"),
                       width = 8, height = 4)
        }

        # dump the charts into a folder
        purrr::map(list(chart), function(x) {
                lapply(1:length(theList), function(y) {
                        theList[[y]] %>% x
                })        
        })
        
        # reset wd
        setwd(old.dir)
}

########################################
############# run function #############
########################################
dumpChart(df,  # the data.frame object, ususally first ingested from an Excel or csv input
          attribute = "attribute",  # name of the attribute column
          label = "label",  # name of the labelling column, which contains the features
          value = "odds",  # name of the result column, which contains the odds 
          threshold = 0,  # the threshold for the odds, i.e. select only features larger than this threshold
          n = 15,  # number of maximum features selected 
          foldername = "charts")  # name of the folder where the charts will be stored























