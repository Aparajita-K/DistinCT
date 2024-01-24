# DistinCT: Deciphering CT Indications in Lung Cancer Survivors

## Overview
DistinCT is an R package designed for abstraction of CT imaging indications in long-term lung cancer survivors. The package provides tools for reading and pre-processing electronic health records (EHR), including CT scan reports, extracting structured EHR and NLP features, and applying a fitted logistic regression model. The logistic regression predicts whether CT scans are performed for surveillance or other reasons.

## Package Installation

You can install the development version of DistinCT from GitHub with:

```R
# install.packages("devtools")
devtools::install_github("Aparajita-K/DistinCT")
```

## Usage

The DistinCT package is straightforward to use. Below is a basic workflow demonstrating how to load sample data, extract features, and predict CT scan indications.

Example usage:

### Read and Validate Input Data

The input data should be a data frame or in CSV or Excel format with the following columns:

- `patient_id`: Unique identifier for the patient (character or numeric).
- `diagnosis_date`: Date of initial diagnosis in "YYYY-MM-DD" format.
- `ct_date`: Date of the CT scan in "YYYY-MM-DD" format.
- `provider_type`: Type of provider ordering the CT scan (character).
- `report`: Text of the CT scan report (character).
- `symptom_diagnosis`, `lungdisease_diagnosis`, `Xray_count`: Additional structured EHR fields.

The `read_data` function reads and validates data from a CSV or Excel file, or an existing data frame. 

```R
library(DistinCT)

# Load sample data
path_to_data <- system.file("data", "SyntheticData.xlsx", package = "DistinCT")
data <- read_data(path_to_data)
```

### Feature Extraction

The `feature_extract` function processes the input data to extract structured EHR and NLP features. 
It prepares the data for subsequent analysis and prediction.

```R
# Extract features
feature_data <- feature_extract(data)
```

### Predict CT Scan Indications

The `predict_indication` function applies a pre-trained logistic regression model to predict the indication for CT scans in long-term lung cancer survivors. It classifies each scan as either 'Surveillance' or 'Other Reasons' based on structured EHR and NLP features. 

#### Parameters:
- `feature_data`: A data frame containing features extracted by the `feature_extract` function, including EHR Features (e.g., 'priorCT_6mon', 'provider_med', 'provider_onc', 'symptom_binary', 'LungDis_binary', 'Xray_count') and NLP Features (e.g., 'DefinitiveTreat', 'Surveillance', 'Recurrence', 'FollowUp', 'Metastasis', 'Symptom', 'LC_Treat_Drug').
- `binarize_thr`: A number in [0, 1] to specify the binarization threshold for classifying 'Surveillance' vs 'Other Reasons'. If set to NA (default), the threshold from the saved model is used.
- `writeFile`: A logical value indicating whether to write the output to an Excel file. Defaults to TRUE.
- `outputFilePath`: The file path for the Excel output file. Defaults to "Predictions.xlsx" in the current working directory.

#### Output:
The function returns a data frame identical to `feature_data` but with two additional columns: `Prediction_Probability` and `CT_indication`. `Prediction_Probability` contains the real-valued probability of a CT scan being for 'Surveillance', and `CT_indication` contains the prediction 'Surveillance' or 'Other Reasons'. If `writeFile` is TRUE, the output is also saved as an Excel file.

Example Usage:
```R
# Predict CT scan indications and write to an Excel file
predictions <- predict_indication(feature_data, 
                                  writeFile = TRUE, 
                                  outputFilePath = "Model_Predictions.xlsx")

# Predict CT scan indications with a custom binarization threshold
predictions_custom_thr <- predict_indication(feature_data, binarize_thr = 0.5)
```

## Contact Information

For any questions or feedback regarding the DistinCT package, feel free to reach out to the authors:

- Aparajita Khan - [aparjita@stanford.edu](mailto:aparjita@stanford.edu)
- Summer Han - [summerh@stanford.edu](mailto:summerh@stanford.edu)
