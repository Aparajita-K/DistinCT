# DistinCT Package Demo
# This script demonstrates how to use the DistinCT package to process and analyze
# CT scan data from lung cancer survivors. It includes steps for reading data,
# extracting features, and predicting CT scan indications using a synthetic data
# file provided with package.

### Load required packages
library(readxl)
library(writexl)
library(stringr)
library(rms)
library(utils)

####
# source('R/feature_extract.R')
# source('R/predict_indication.R')
# source('R/read_data.R')
# source('R/utils.R')

# --- Step 1: Load Sample Data ---

# Construct the path to the sample data file included in the DistinCT package.
# 'SyntheticData.xlsx' is assumed to be located in the 'data' directory of the package.
path_to_data <- system.file("data", "SyntheticData.xlsx", package = "DistinCT")
if(!file.exists(path_to_data)) {
    path_to_data = "data/SyntheticData.xlsx"
    if(!file.exists(path_to_data))
        stop("SyntheticData.xlsx not found in the package data directory. Please provide a valid data file.")
}

# Read the data using the read_data function from the DistinCT package.
# This function is designed to read and preprocess input data to ensure
# all required information is present.
data = read_data(path_to_data)

# --- Step 2: Feature Extraction ---

# Extract relevant features from the data using the feature_extract function.
# This function processes the input data to extract both structured EHR and NLP features,
# preparing it for the predictive model.
feature_data = feature_extract(data)

# --- Step 3: Predict CT Scan Indications ---

# Use the predict_indication function to predict the indication for each CT scan.
# The function applies a fitted logistic regression model and returns the input data frame with
# additional columns for the prediction probability and the predicted indication
# ('Surveillance' or 'Other Reasons').
predictions = predict_indication(feature_data)

# The 'predictions' data frame now contains the results of the analysis.
# It can be further examined or exported as needed.


