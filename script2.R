## Prediction San Francisco Crime 
## Import Library

library(plyr)
library(dplyr)
library(ggmap)
library(ggplot2)
library(readr)
library (e1071)
library(sqldf)
library(caret)
library(klaR)
library(ggplot2)
## Load data
train <- read.csv(file="C://Users/geevee/Desktop/train.csv",head=TRUE,sep=",")
test <- read.csv(file="C://Users/geevee/Desktop/test.csv",head=TRUE,sep=",")

train2 <- train
train2$Descript <- NULL

# Add New Columns to data frame train2
date = strptime(train2$Dates,"%Y-%m-%d %H:%M:%S")
train2["Year"] <- paste("A", format(date,"%Y"))
train2["Month"] <- paste("M", format(date,"%m"))
train2["Day"] <-  paste("D",format(date,"%d"))
train2["Hour"] <-  format(date,"%H")
train2["HourC"] <-  paste("D",format(date,"%H"))
train2["DayDec"] <-  paste("DD",substr(format(date,"%d"),1,1))

# Function to classify the Hour
intervallOrario <- function(x) { 

if(x >= 0 & x < 5) y <- "NIGHT"
if(x >= 5 & x < 9) y <- "PRE-JOB"
if(x >= 9 & x < 13) y <- "MORNING"
if(x >= 13 & x < 18) y <- "AFTERNOON"
if(x >= 18 & x <= 24) y <- "EVENING"

return(y)
}
#print("Debug 30")

train2["CatHour"] <- sapply(train2$Hour,intervallOrario)

#print("Debug 40")

## Choose the Crime with the maximum number of occurrency
dfTmpMax <- sqldf('select Category,PdDistrict,CatHour,Month,DayDec, count(*) nro from train2 group by Category,PdDistrict,CatHour,Year,Month,Day order by 2')
dfTrainFinal <- ddply(dfTmpMax,~CatHour+PdDistrict+Month+DayDec,function(x){x[which.max(x$nro),]})
# Delete the Column nro
dfTrainFinal$nro <- NULL


### Prepare Test Data
test2 <- test
test2$X_round <- round_any(test2$X, 0.005)
test2$Y_round <- round_any(test2$Y, 0.005)
#Concatenate X_round and Y_round
test2$X_Y <- as.factor(paste(test2$X_round, test2$Y_round, sep = " "))

date = strptime(test2$Dates,"%Y-%m-%d %H:%M:%S")
test2["Year"] <- paste("A", format(date,"%Y"))
test2["Month"] <- paste("M", format(date,"%m"))
test2["Day"] <-  paste("D",format(date,"%d"))
test2["Hour"] <-  format(date,"%H")

test2["DayDec"] <-  paste("DD",substr(format(date,"%d"),1,1))

#print("Debug 80")
test2["CatHour"] <- sapply(test2$Hour,intervallOrario)

#print("Debug 90")
dfTestFinal <- sqldf('select distinct PdDistrict,CatHour,Month,DayDec from test2 ')


######################################
# Naive Bayes Testing the model
######################################

split=0.80
trainIndex <- createDataPartition(dfTrainFinal$Category, p=split, list=FALSE)
data_train2 <- dfTrainFinal[ trainIndex,]
data_test2 <- dfTrainFinal[-trainIndex,]

#print("Debug 120")
model <-  naiveBayes(Category ~ ., data = data_train2)

# make predictions
x_test2 <- data_test2[,2:5]
y_test2 <- data_test2[,1]
predictions <- predict(model, x_test2)

#print("Debug 150")

cm <-confusionMatrix(predictions, y_test2)   #confusion matrix created to test accuracy
print(cm)


############################################
# Naive Bayes Create The Model
############################################

modelFinal <- naiveBayes(Category ~ ., data = dfTrainFinal)


#dfTestFinal <- head(dfTestFinal,300)

#final <- predict(model, dfTestFinal, type="class")
predictFinal <- predict(modelFinal, dfTestFinal)

vector_final <- as.character(predictFinal)
dfPrediction <- data.frame(vector_final)

dfTestFinal["CategoryPred"] <- dfPrediction
dfTestFinal2<-dfTestFinal
dfTestFinal2<-data.frame(dfTestFinal2)
str(dfTestFinal2)
#graph to show the ocurrence of the crimes predicted
ggplot(dfTestFinal2,aes(x=CategoryPred)) +geom_bar(fill="steelblue",width=0.5)+xlab("Category")+ylab("ocurrence")
#graph to show in which district and in which Month the crimes are most prevalent
ggplot(dfTestFinal2, aes(x=PdDistrict,y=Month, fill=CategoryPred)) +  geom_bar(stat="identity", position=position_dodge())


