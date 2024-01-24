#' Read and Validate Data for CT Indication Prediction
#'
#' This function reads data from a CSV or Excel file or an existing data frame,
#' checks for the presence of required columns, and validates their data types.
#' Optional columns are checked if they exist. The function also specifies a
#' date format for date columns and converts columns to the correct data type.
#'
#' @param input_data A file path to a CSV/Excel file or a data frame.
#' @return A data frame with validated and correctly typed columns.
#' @export
#'
#' @examples
#' # Assuming 'data.xlsx' is in your working directory and has the correct structure
#' read_data("data.xlsx")
#' # For an existing data frame named 'dframe'
#' read_data(dframe)
#'
#' @details
#' Compulsory columns:
#' \itemize{
#'   \item \code{patient_id}: Unique identifier for the patient (required, character or numeric).
#'
#'   \item \code{diagnosis_date}: Date of the initial diagnosis (required, expected in "YYYY-MM-DD" format).
#'
#'   \item \code{ct_date}: Date of the CT scan (required, expected in "YYYY-MM-DD" format).
#'
#'   \item \code{provider_type}: Type of provider ordering the CT scan (required, character),
#'         examples include Internal Medicine, Emergency Medicine, Radiation Oncology, Medical Oncology, etc.
#'
#'   \item \code{report}: Text of the CT scan report (required, character).
#'
#'   \item \code{symptom_diagnosis}: Binary indicator of whether the patient was diagnosed with symptoms
#'         like fever, cough, chest pain, shortness of breath within 6 months prior to the current CT
#'         (required, 1 for presence, 0 for absence, or numeric counts).
#'
#'   \item \code{lungdisease_diagnosis}: Binary indicator of whether the patient was diagnosed with lung
#'         diseases like pleural effusion, pneumonia, hemoptysis, dyspnea, emphysema, COPD within 6 months
#'         prior to the current CT
#'         (required, 1 for presence, 0 for absence, or numeric counts).
#'
#'   \item \code{Xray_count}: Count of X-ray scans 6 months prior to the current CT (required, numeric).
#'
#' }
#' Optional columns:
#' \itemize{
#'
#'   \item \code{symptom_names}: Names of symptoms reported (optional).
#'
#'   \item \code{lungdisease_names}: Names of lung diseases diagnosed (optional).
#'
#' }
#'
read_data <- function(input_data) {
    # Function body follows...

    # Initialize the data frame
    data <- NULL

    # Check if input_data is a file path
    if (is.character(input_data)) {
        # Determine the file type and read the file accordingly
        if (grepl("\\.csv$", input_data, ignore.case = TRUE)) {
            data <- read.csv(input_data, stringsAsFactors = FALSE)
        } else if (grepl("\\.(xls|xlsx)$", input_data, ignore.case = TRUE)) {
            data <- readxl::read_excel(input_data)
        } else {
            stop("File type not supported. Please provide a CSV or Excel file.")
        }
    } else if (is.data.frame(input_data)) {
        # If it's a data frame, use it directly
        data <- input_data
    } else {
        stop("Invalid input_data type. Please provide a file path or a data frame.")
    }


    # Define the required columns and their expected data types
    required_columns <- c("patient_id", "diagnosis_date", "ct_date", "provider_type", "report",
                          "symptom_diagnosis", "lungdisease_diagnosis", "Xray_count")

    # Define optional columns
    optional_columns <- c("symptom_names", "lungdisease_names")


    # Check for missing required columns
    missing_columns <- setdiff(required_columns, names(data))
    if (length(missing_columns) > 0) {
        stop(paste("The following required columns are missing:", paste(missing_columns, collapse = ", ")))
    }

    # Check for optional columns and include them if present
    existing_optional_columns <- intersect(optional_columns, names(data))
    all_columns <- c(required_columns, existing_optional_columns)

    # Raw data read from file
    View(data)

    # Convert patient_id to character
    data$patient_id <- as.character(data$patient_id)

    # Check data types for specific required columns
    required_character_columns <- c("provider_type", "report")

    # Check if the required character columns are indeed of type character
    if (!all(sapply(data[required_character_columns], is.character))) {
        stop("The 'provider_type' and 'report' columns must be of type character.")
    }

    # Check for required columns and convert them to the correct data type
    if (!"ct_date" %in% names(data) || !all(sapply(data["ct_date"], function(x) is.character(x) || is.Date(x)))) {
        stop("ct_date column must be of type character or Date.")
    }
    if (!"Xray_count" %in% names(data) || !all(sapply(data["Xray_count"], is.numeric))) {
        stop("Xray_count column must be of type numeric.")
    }
    if (!"symptom_diagnosis" %in% names(data) || !all(sapply(data["symptom_diagnosis"], is.numeric))) {
        stop("symptom_diagnosis column must be of type numeric.")
    }
    if (!"lungdisease_diagnosis" %in% names(data) || !all(sapply(data["lungdisease_diagnosis"], is.numeric))) {
        stop("lungdisease_diagnosis column must be of type numeric.")
    }

    # Convert ct_date and diagnosis_date to Date class if they are characters
    date_cols <- c("ct_date", "diagnosis_date")
    for (col in date_cols) {
        if (col %in% names(data) && is.character(data[[col]])) {
            data[[col]] <- as.Date(data[[col]], format = "%Y-%m-%d")
        }
    }

    # Check for negative values and convert to binary for specific columns
    numeric_columns <- c("Xray_count", "symptom_diagnosis", "lungdisease_diagnosis")

    # Initialize a message container for user notifications
    user_messages <- c()

    # Ensure symptom_diagnosis and lungdisease_diagnosis are binary (0/1)
    for (col in numeric_columns) {
        if (col %in% names(data)) {
            data[[col]]  <- as.numeric(data[[col]])
            if (any(data[[col]] < 0, na.rm = TRUE))
                user_messages <- c(user_messages, paste("\n Negative values in", col, "have been set to 0."))
            data[[col]] <- ifelse(data[[col]] < 0, 0, data[[col]])
        }
    }

    # If there are user messages, show them
    if (length(user_messages) > 0) {
        for (msg in user_messages) {
            message(msg)
        }
    }

    # data after performing necessary checks
    head(subset(data,select=-report))
    View(data)

    # Return the validated and type-converted data frame
    return(data[all_columns])
}
