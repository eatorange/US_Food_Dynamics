# import data
library(readxl)
geraniums <- read_excel("Downloads/geraniums.xlsx")

# make Treatment a factor
treatment.f = as.factor(geraniums$Treatment)

# generate ANOVA table
summary(aov(geraniums$Weight ~ treatment.f))
