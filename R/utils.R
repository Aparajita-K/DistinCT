#' Compute CT Scan Intervals
#'
#' This function calculates the time intervals between successive CT scans for each patient
#' in a given data frame. It adds a new column to the data frame indicating the number of months
#' since the previous CT scan for each scan. For the first scan of each patient, this value is set to zero.
#' Additionally, it creates a binary indicator showing whether the interval since the last CT scan
#' exceeds a specified number of months.
#'
#' @param df A data frame containing CT scan data, including patient IDs and scan dates.
#'           The data frame should have columns `patient_id` and `ct_date`.
#' @param interval_months The number of months to use as a threshold for the binary indicator.
#'                        Defaults to 6 months.
#' @return A modified data frame with two additional columns: `diff_prev_ct_months` indicating the
#'         number of months since the last CT scan, and `priorCT_6mon` as a binary indicator for
#'         intervals over the specified number of months (default=6).
#' @export
#' @examples
#' # Assuming 'sample_df' is a data frame with 'patient_id' and 'ct_date' columns
#' # Compute CT scan intervals using the default 6 months interval
#' interval_data <- compute_ct_intervals(sample_df)
#' # Compute CT scan intervals using a different interval (e.g., 3 months)
#' interval_data <- compute_ct_intervals(sample_df, interval_months = 3)
#'
compute_ct_intervals <- function(df, interval_months = 6) {
    # Order the entire dataframe by patient_id and ct_date
    df <- df[order(df$patient_id, as.Date(df$ct_date)), ]

    # Initialize columns for CT scan intervals and binary indicator
    df$diff_prev_ct_months <- numeric(nrow(df))
    df$priorCT_6mon <- integer(nrow(df)) # Initializes to 0

    # Define the threshold for the binary indicator
    thrsh <- interval_months

    # Loop over each row in the ordered dataframe
    for(i in 2:nrow(df)) {
        # Check if the current row and the previous row belong to the same patient
        if(df$patient_id[i] == df$patient_id[i - 1]) {
            # Calculate the difference in months between the current and previous CT scan dates
            diff_ct <- difftime(as.Date(df$ct_date[i]), as.Date(df$ct_date[i - 1]), units = "days") / 30
            df$diff_prev_ct_months[i] <- diff_ct

            # Update binary indicator based on the threshold
            df$priorCT_6mon[i] <- as.integer(diff_ct > thrsh)
        } else {
            # For the first CT scan of each patient, set the binary indicator to 1
            df$priorCT_6mon[i] <- 1
        }
    }

    return(df)
}


#' Extract NLP Features from CT Reports
#'
#' This function processes CT report text to extract NLP features based on key phrases.
#' It segments the text into Clinical History, Findings, and Impression sections and
#' calculates the frequency of specific keyphrases as NLP features.
#'
#' @param df A data frame with CT report text and necessary identifiers.
#' @return A data frame with the original data and new NLP feature columns.
#' @export
#' @examples
#' #  Assuming 'data' is a data frame with CT report text and
#' # 'NLPList' and 'NLPFeatureNames' are defined
#' data_with_nlp_features <- extract_nlp_features(data, NLPList, NLPFeatureNames)
#'
extract_nlp_features <- function(df) {

    # Construct the path to the NLPFeatureList RData file within the package
    path_to_rdata <- system.file("data", "NLPFeatureList.RData", package = "DistinCT")

    # Check if the file exists
    if(file.exists(path_to_rdata)) {
        # Load the RData file
        load(path_to_rdata)
    } else {
        path_to_rdata = "data/NLPFeatureList.RData"
        if(file.exists(path_to_rdata)) {
            load(path_to_rdata)
        } else
            stop("NLPFeatureList.RData not found in the package data directory.")
    }

    # CT report segmentation
    # Initialize character vectors for segmented text
    n_obs <- nrow(df)
    ClinHist <- Findings <- Impression <- TextofIntr <- character(n_obs)

    # Loop over each report in the dataframe
    for(i in seq_len(n_obs)) {
        ct_note <- df[i, "report"]

        # Segment Clinical History
        start <- max(
            tail(unlist(gregexpr('CLINICAL HISTORY:', ct_note)), n = 1) + nchar('CLINICAL HISTORY:') + 1,
            tail(unlist(gregexpr('years of age', ct_note)), n = 1) + nchar('years of age') + 1
        )
        stop <- head(unlist(gregexpr('COMPARISON:', ct_note)), n = 1)
        ClinHist[i] <- if (start < stop) substr(ct_note, start, stop - 1) else ""

        # Segment Findings
        start <- head(unlist(gregexpr('FINDINGS:', ct_note)), n = 1) + nchar('FINDINGS:')
        stop <- max(
            head(unlist(gregexpr('IMPRESSION:', ct_note)), n = 1),
            head(unlist(gregexpr('Impression:', ct_note)), n = 1),
            tail(unlist(gregexpr('1. ', ct_note)), n = 1)
        )
        Findings[i] <- if (start < stop) substr(ct_note, start, stop - 1) else ""

        # Segment Impression
        start <- if (stop != -1) stop + nchar('IMPRESSION:') else stop
        stop <- max(
            head(unlist(gregexpr('Physician to Physician Radiology Consult Line', ct_note)), n = 1),
            head(unlist(gregexpr('I have personally reviewed the images for this examination', ct_note)), n = 1)
        )
        Impression[i] <- if (start != -1 && start < stop) substr(ct_note, start, stop - 1) else ""

        # Combine all texts-of-interests together
        TextofIntr[i] <- paste(ClinHist[i], Findings[i], Impression[i])
    }

    # keyphrase based nlp feature extraction

    # Initialize matrix for keyphrase frequency
    tdf <- matrix(0, n_obs, length(NLPFeatureNames))
    colnames(tdf) <- NLPFeatureNames

    # Loop over each segmented text for keyphrase frequency extraction
    for(i in seq_len(n_obs)) {
        FreqNote <- numeric(length(NLPList))

        # Count frequency of each keyphrase
        for(j in seq_along(NLPList)) {
            queryWords <- NLPList[[j]]
            freqCount <- sum(sapply(queryWords, function(kw) length(grep(kw, TextofIntr[i], ignore.case = TRUE))))
            FreqNote[j] <- freqCount
        }

        # Assign frequencies to the matrix
        tdf[i, ] <- FreqNote
    }

    # Combine original data frame with NLP features
    df <- data.frame(df, tdf)


    return(df) # Combine original data frame with NLP features
}


