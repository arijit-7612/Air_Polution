
library(dplyr)
library(readr)
library(randomForest)
library(caret)
library(smotefamily)
library(e1071)
library(corrplot)

setwd("C:\\Users\\HP\\Downloads")
df <- read.csv("air_quality_health_impact_data.csv")

# Feature Engineering
df <- df %>%
  mutate(
    PollutionIndex = 0.4 * PM2_5 + 0.3 * NO2 + 0.3 * O3,
    THI = 0.8 * Temperature + 0.2 * Humidity,
    RespiratoryRisk = ifelse(RespiratoryCases > 5, 1, 0),
    CardioRisk = ifelse(CardiovascularCases > 5, 1, 0)
  ) %>%
  select(-CardiovascularCases, -RespiratoryCases)

# Training Features
features <- c("PollutionIndex", "THI", "SO2", "PM10", "AQI")

X <- as.data.frame(scale(df[, features]))
y <- df$RespiratoryRisk

# Balancing the dataset
set.seed(42)
smote_balanced <- SMOTE(X, y, dup_size = 4, K = 5)
X_balanced <- smote_balanced$data[, 1:ncol(X)]
y_balanced <- as.factor(smote_balanced$data$class)

# Split 
train_bal <- createDataPartition(y_balanced, p = 0.8, list = FALSE)
X_train_bal <- X_balanced[train_bal, ]
y_train_bal <- y_balanced[train_bal]
X_test_bal <- X_balanced[-train_bal, ]
y_test_bal<- y_balanced[-train_bal]

# Random Forest
rf1 <- randomForest(x = X_train_bal, y = y_train_bal, ntree = 100)
pred_resp <- predict(rf1, X_test_bal)

cat("Respiratory Risk\n")
print(confusionMatrix(pred_resp, y_test_bal))



#For Cardio 

X_cardio <- as.data.frame(scale(df[, features]))
y_cardio <- df$CardioRisk 

set.seed(42)
balance_cardio <- SMOTE(X_cardio, y_cardio, dup_size = 4, K = 7)
X_cardio <- smote_cardio$data[, 1:ncol(X_cardio)]
y_cardio <- as.factor(balance_cardio$data$class)

train_cardio <- createDataPartition(y_cardio_smote, p = 0.8, list = FALSE)
X_train_cardio <- X_cardio_smote[train_cardio, ]
y_train_cardio <- y_cardio_smote[train_cardio]
X_test_cardio <- X_cardio_smote[-train_cardio, ]
y_test_cardio <- y_cardio_smote[-train_cardio]

# Train model
rf2 <- randomForest(x = X_train_cardio, y = y_train_cardio, ntree = 100)
pred_cardio <- predict(rf2, X_test_cardio)

cat("\n : Cardio Risk\n")
print(confusionMatrix(pred_cardio, y_test_cardio))


cat("\nImportance (Respiratory Risk):\n")
print(importance(rf1))

cat("\nImportance (CArdiovascular Risk):\n")
print(importance(rf2))

percent_zero <- mean(df$CardioRisk == 0) * 100
percent_one <- mean(df$CardioRisk == 1) * 100
cat(sprintf("\n✅ Percentage of CardioRisk = 0: %.2f%%\n", percent_zero))
cat(sprintf("✅ Percentage of CardioRisk = 1: %.2f%%\n", percent_one))