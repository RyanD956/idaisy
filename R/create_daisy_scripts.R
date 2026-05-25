#' Create daisy scripts using a dataframe and a template file
#' @importFrom readr read_file
#' @importFrom whisker whisker.render
#' @param df A dataframe containing the parameters for each simulation. Each row will correspond to one simulation script.
#' @param template_path The file path to a whisker template (.txt) that will be used to generate the daisy scripts. The template should use tags that match the column names in `df`.
#' @param dir The directory where the generated daisy scripts will be saved. Each simulation will be saved in a subfolder named after the `sim_name` column in `df`.
#' @return Invisibly returns a character vector of the paths to the created .dai files.
#' @export
#'
#'
create_daisy_scripts <- function(df, template_path, dir) {
  if (!is.data.frame(df)) {
    stop("`df` must be a data.frame.", call. = FALSE)
  }
  if (!"sim_name" %in% names(df)) {
    stop("`df` must contain a 'sim_name' column.", call. = FALSE)
  }
  if (any(is.na(df$sim_name)) || any(df$sim_name == "")) {
    stop("`sim_name` contains missing/empty values.", call. = FALSE)
  }
  if (anyDuplicated(df$sim_name) > 0) {
    stop("`sim_name` contains duplicate values.", call. = FALSE)
  }
  if (!file.exists(template_path)) {
    stop("Template file doesn't exist.", call. = FALSE)
  }
  if (!dir.exists(dir)) {
    stop("Directory doesn't exist.", call. = FALSE)
  }

  message("Simulations will be created in: ", dir)

  template_file <- read_file(template_path)
  template_name <- basename(template_path)

  # Create local copy of and sanitize names
  local_df <- df
  local_df$row_id <- seq_len(nrow(local_df))
  local_df$date_created <- Sys.Date()
  local_df$dir <- dir
  local_df$template <- template_name
  local_df$sim_name <- gsub('[<>:"/\\\\|?*]', "_", local_df$sim_name)

  # Create simulation directories
  sim_dirs <- file.path(dir, local_df$sim_name)

  for (d in sim_dirs) {
    dir.create(d, recursive = TRUE, showWarnings = FALSE)
  }

  # Loop through each row and write a daisy script using the template
  out_paths <- character(nrow(local_df))

  for (i in seq_len(nrow(local_df))) {
    row_list <- as.list(local_df[i, , drop = FALSE]) # Drop = FALSE to keep it as a data.frame

    # Convert NAs to NULL for whisker
    row_list <- lapply(row_list, function(x) {
      if (length(x) == 1 && is.na(x)) NULL else x
    })

    text <- whisker.render(template_file, data = row_list)

    # Fix line endings to ensure output matches template
    text <- gsub("\r\n", "\n", text, fixed = TRUE)

    # Add to out_paths
    sim_name <- row_list$sim_name[[1]]
    out_paths[i] <- file.path(sim_dirs[i], paste0(sim_name, ".dai"))

    # Write file
    cat(text, file = out_paths[i], sep = "")
  }

  message("Created ", nrow(local_df), " daisy scripts.")

  # Return paths invisibly so callers can chain or inspect
  invisible(out_paths)
}
