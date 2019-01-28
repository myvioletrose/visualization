This is a custom function that takes a data frame and create a bar chart (using ggplot2) for each attribute and then saves each one of these charts into a different folder. In this example, we have an input excel file. Mainly, we focus on the "attribute", "value" and "odds" columns. There are many attributes (such as age, education, lifestyle, topic_1, etc.). Each attribute has multiple labels or values and each of them is associated with one numeric number (odds). Running this function would automate as many charts as there are number of attributes; each bar chart would feature a single attribute with top n labels and their associated odds in descending order (setting up thresholds for extracting n labels and odd value, as well as providing a folder name is optional).

The function would require these inputs,

dumpChart(df,  # the data.frame object, ususally first ingested from an Excel or csv input
          attribute = "attribute",  # name of the attribute column
          label = "label",  # name of the labelling column, which contains the features
          value = "odds",  # name of the result column, which contains the odds 
          threshold = 0,  # the threshold for the odds, i.e. select only features larger than this threshold
          n = 15,  # number of maximum features selected 
          foldername = "charts")  # name of the folder where the charts will be stored