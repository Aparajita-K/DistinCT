#' Extract Features for CT Indication Prediction
#'
#' This function processes the input data frame to extract both structured EHR and NLP features.
#' It prepares the data for use in a logistic regression model, which will predict
#' whether each CT scan was performed for surveillance or other reasons.
#'
#' @param data A data frame with the required columns.
#' @return A data frame with extracted features.
#' @export
#'
#' @examples
#' # Assuming 'data' is a data frame with the correct structure
#' features <- feature_extract(data)
#'
#' @details
#' The function focuses on extracting features from the following columns:
#' \itemize{
#'   \item \code{patient_id}: Used to identify which CT reports belong to same patient.
#'
#'   \item \code{diagnosis_date} and \code{ct_date}: Used to extract scan interval
#'         related temporal features.
#'
#'   \item \code{provider_type}: Used for extracting provider-related features.
#'
#'   \item \code{report}: NLP analysis performed to extract key phrase features.
#'
#'   \item \code{symptom_diagnosis}, \code{lungdisease_diagnosis}, \code{Xray_count}:
#'         Utilized as part of structured EHR features.
#' }
#'
#' The NLP analysis of the CT report consists of a six-step pipeline:
#' \enumerate{
#'   \item Segmentation: Dividing the text into meaningful segments (eg. Clinical History, Findings, Impression).
#'   \item Tokenization: Breaking down the text into individual words or tokens.
#'   \item Parts of Speech Tagging: Identifying the parts of speech for each token for phrase analysis.
#'   \item Key Phrase Analysis: Extracting important phrases from the text.
#'   \item Frequency-Based Feature Extraction: Analyzing the frequency of key terms and phrases.
#' }
#'
#'
feature_extract <- function(data) {
# Validate input
if (!is.data.frame(data)) {
    stop("Input must be a data frame.")
}

# Ensure all required columns are present
required_columns <- c("patient_id", "diagnosis_date", "ct_date", "provider_type", "report",
                      "symptom_diagnosis", "lungdisease_diagnosis", "Xray_count")
if (!all(required_columns %in% names(data))) {
    stop("Missing one or more required columns in the data frame.")
}

# EHR Feature Extraction

# Apply the CT interval computation function to the data
data <- compute_ct_intervals(data)

# Other EHR features
prov <- data$provider_type
data$provider_onc <- as.integer(grepl('Oncology', prov, ignore.case = TRUE))
data$provider_med <- as.integer(grepl('Medicine', prov, ignore.case = TRUE))
data$symptom_binary <- ifelse(data$symptom_diagnosis > 0, 1, 0)
data$LungDis_binary <- ifelse(data$lungdisease_diagnosis > 0, 1, 0)


# NLP Feature Extraction from CT Report
data <- extract_nlp_features(data)


# data after extraction of structured EHR and NLP features
head(subset(data,select=-report))
View(data)

# Return the data frame with added feature columns
return(data)  # Placeholder, replace with the actual data frame with features
}

