Suppose we work in a global ecommerce company. We have brands that can sell/ship to multiple global destinations. We can calculate an Average Order Value (AOV) by country and by brand. To illustrate, here's a completely mock-up dataset that has only three columns, i.e. "brand", "country" and "aov". 

The global marketing team wants to know the brand performance by country. Put it this way, how can we visually summarize the AOV by country for each brand in this data set? For each brand (or country), can we visually display and group countries with similar AOV (or any KPI) together in one chart? Suppose "brand 27" is sold to 100+ countries, can we visually present and cluster the markets together by similar AOV? Alternatively, over 20+ brands are shipping to Bermuda, which brands are having higher AOV?

We can apply a for-loop and create an advanced dotplot using ggplot2 and ggrepel to solve the above questions.

(only a subset of figures are included in this repo because of upload size restriction)
