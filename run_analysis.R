# Project for Getting and Cleaning Data, Coursera.
# See https://github.com/dgraziotin/GCD-project for more.
# The license of this script is the WTFPL (see COPYING)
# Only thing you need to do is to setup the following variable to be your working directory.

working.directory <- "" # '/' works in R windows, too.

if (nchar(working.directory) == 0){
  stop("In order to use this script, please setup the working.directory variable to point to your working directory")
}

setwd(working.directory)

# installs some dependencies (if not already installed) and load them
if (!require("stringr")){
  install.packages("stringr", dependencies=TRUE)
}

library("stringr")

if (!require("reshape")){
  install.packages("reshape", dependencies=TRUE)
}

library("reshape")

# prepares the data folder where the original dataset is downloaded
if(!file.exists("data")){
  dir.create("data")
}

setwd("data")

if(!file.exists("dataset.zip")){
  download.file(url='https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip' ,destfile="dataset.zip")
}

unzip("dataset.zip")

if(!file.exists("UCI HAR Dataset")){
  stop("Extracted dataset does not work. Please make sure that the correct dataset is downloaded")
}

setwd("UCI HAR Dataset")

# The following steps are documented in the CodeBook.md file

# Loads the features

features <- read.table("features.txt", header=FALSE)
features.colnames <- features$V2

xtrain <- read.table("train/X_train.txt", header=FALSE, col.names=features.colnames)
xtest <- read.table("test/X_test.txt", header=FALSE, col.names=features.colnames)

features <- rbind(xtrain, xtest)

# 2 Extracts only the measurements on the mean and standard deviation for each measurement. 
features <- features[, grep(".*\\.(mean|std)\\.\\..*", names(features), value=T)]

subjects.colnames <- c("subject")
subjecttrain <- read.table("train/subject_train.txt", header=FALSE, col.names=subjects.colnames)
subjecttest <- read.table("test/subject_test.txt", header=FALSE, col.names=subjects.colnames)

subjects <- rbind(subjecttrain, subjecttest)

activities.colnames <- c("activity")
activitytrain <- read.table("train/y_train.txt", header=FALSE, col.names=activities.colnames)
activitytest <- read.table("test/y_test.txt", header=FALSE, col.names=activities.colnames)

activities <- rbind(activitytrain, activitytest)

# 3 Uses descriptive activity names to name the activities in the data set

activity.labels <- read.table("activity_labels.txt", header=FALSE, col.names=c("activity", "activityName"))
activities <- merge(activities, activity.labels, by="activity", sort=F)

subject.activities <- cbind(subjects, data.frame(activity = activities$activityName))

# 1 Merges the training and the test sets to create one data set.
df <- cbind(features, subject.activities)

# 4 Appropriately labels the data set with descriptive activity names.
colnames(df) <- tolower(str_replace_all(colnames(df), "([A-Z]{1})", ".\\1"))
colnames(df) <- str_replace_all(colnames(df), "[\\.]+", ".")
colnames(df) <- str_replace_all(colnames(df), "[\\.]+$", "") # extra dot at the end of the string

tidy <- df[0,]
tidy[1,] <- rep(NA, 68)
  
melted <- melt(df, id=c("subject","activity"))

# 5 Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 

# This is not that much optimized. Still, it works.

for(subj in unique(melted$subject)){
  means <- c()
  for(acti in unique(melted[melted$subject == subj,]$activity)){
    for(vari in unique(melted[melted$subject == subj,]$variable)){
      m <- mean(melted[melted$subject == subj & melted$activity == acti & melted$variable == vari,]$value)
      means <- append(means, as.numeric(m))
    }
    means <- append(means, subj)
    means <- append(means, acti)
    tidy <- rbind(tidy, means)
  }
}

# remove the first N/A row
tidy <- na.omit(tidy)

# re-orderding of columns: first subject, then activity, then the values
tidy <- tidy[,c(67,68, 1:66)]

setwd(working.directory)


write.table(tidy, file="tidymeans.txt", quote=FALSE)
