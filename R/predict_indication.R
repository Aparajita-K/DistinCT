#' Predict CT Scan Indications
#'
#' This function applies a pre-trained logistic regression model to predict the indication
#' for CT scans in long-term lung cancer survivors. It classifies each scan as either
#' 'Surveillance' or 'Other Reasons' based on structured EHR and NLP features. The binarization
#' threshold can be specified, or the default from the model is used. If `writeFile`
#' is set to TRUE, the function also writes the output to an Excel file.
#'
#' @param feature_data A data frame containing the features extracted by the `feature_extract` function.
#' The data frame should include the following features:
#' EHR Features: 'priorCT_6mon', 'provider_med', 'provider_onc', 'symptom_binary', 'LungDis_binary', 'Xray_count'.
#' NLP Features: 'DefinitiveTreat', 'Surveillance', 'Recurrence', 'FollowUp', 'Metastasis', 'Symptom', 'LC_Treat_Drug'.
#'
#' @param binarize_thr Binarization threshold as a number in [0, 1] to classify 'Surveillance' vs 'Other Reasons'.
#'                     If set to NA (default), the threshold from the saved model is used.
#'
#' @param writeFile A logical value indicating whether to write the output to an Excel file.
#' Defaults to TRUE.
#'
#' @param outputFilePath A string specifying the file path for the Excel output file.
#' If writeFile is TRUE and no path is provided, the default is "Predictions.xlsx" in the
#' current working directory.
#'
#' @return A data frame identical to `feature_data` but with two additional columns:
#' `Prediction_Probability` and `CT_indication`. `Prediction_Probability` contains the
#' real-valued probability of a CT scan being for 'Surveillance', and `CT_indication`
#' contains the prediction 'Surveillance' or 'Other Reasons'. If `writeFile` is TRUE,
#' the output is also saved as an Excel file.
#'
#' @importFrom writexl write_xlsx
#' @importFrom utils View
#' @importFrom utils head
#' @importFrom utils read.csv
#' @importFrom utils tail
#'
#' @examples
#' # Assuming `feature_data` is a data frame with the required features
#' predictions <- predict_indication(feature_data,
#'                                  writeFile = TRUE,
#'                                  outputFilePath = "Model_Predictions.xlsx")
#' predictions <- predict_indication(feature_data)
#' predictions_custom_thr <- predict_indication(feature_data, binarize_thr = 0.5)
#'
#' @export
predict_indication <- function(feature_data,
                               binarize_thr = NA,
                               writeFile = TRUE,
                               outputFilePath = "Predictions.xlsx") {
    # Function implementation

    # Construct the path to the NLPFeatureList RData file within the package
    path_to_rdata <- system.file("data", "HybridModel.RData", package = "DistinCT")

    # Check if the file exists
    if(file.exists(path_to_rdata)) {
        # Load the RData file
        load(path_to_rdata)
    } else {
        path_to_rdata = "data/HybridModel.RData"
        if(file.exists(path_to_rdata)) {
            load(path_to_rdata)
        } else
            stop("HybridModel.RData not found in the package data directory.")
    }

    # Define positive and negative classes
    posClass <- "Surveillance"
    negClass <- "Other Reasons"

    # Check dimensions of the input data
    cat("\n Input data dimension:", dim(feature_data))

    # Generate real-valued predictions
    predictedValues <- round(predictrms(ProposedModel, feature_data), 4)
    predictedValues <- 1 / (1 + exp(-predictedValues))  # Convert to probabilities
    predictedValues[abs(predictedValues) < 0.0001] <- 0
    predictedValues <- unname(predictedValues)
    cat("\n Max prediction value = ", max(predictedValues), " Min prediction value = ", min(predictedValues))

    # Add the predictions to the data frame
    feature_data$Prediction_Probability <- predictedValues

    # Determine the cutoff for binarization
    cutoff <- if (is.na(binarize_thr)) ProposedCutOff else binarize_thr
    cat("\n Binarization threshold used:",cutoff)

    # Apply cutoff to generate binary labels
    binaryLabels <- ifelse(predictedValues > cutoff, posClass, negClass)
    binaryLabels <- factor(binaryLabels)
    feature_data$CT_indication <- binaryLabels


    # Display a summary table of the predicted labels
    cat("\n Summary of Predicted Labels:\n")
    print(table(feature_data$CT_indication))

    # Write to Excel file if writeFile is TRUE
    if (writeFile) {
        writexl::write_xlsx(feature_data, outputFilePath)
        cat("\n Predictions written to file:", outputFilePath)
    }

    return(feature_data)
}
