#' Collate outputs from Daisy simulations into a list of data.tables
#' @importFrom data.table fread setnames set rbindlist :=
#' @importFrom furrr future_map
#' @importFrom future plan availableCores multisession
#' @importFrom janitor make_clean_names
#' @importFrom utils type.convert
#' @importFrom tools file_path_sans_ext
#' @param dir Directory containing the Daisy simulation outputs. The function will search for .dlf files in all subdirectories. Expected structure is dir/sim_name/outputsfile.dlf; sim_name is derived from two levels above each .dlf file.
#' @param required_outputs A character vector of output types to load, e.g. c("harvest", "crop_prod"). If "all", all unique .dlf file types will be loaded.
#' @param sims_to_load A character vector of simulation names to load, e.g. c("sim1", "sim2"). If "all", all simulations found in the directory will be loaded.
#' @param combine_results Whether to combine all output types into a single data.table. Defaults to FALSE (returns a list of dataframes). If TRUE, all output types must have the same number of rows.
#' @return If combine_results is FALSE, a named list of data.tables, one per .dlf file type, with a sim_id column identifying the originating simulation. If combine_results is TRUE, a single data.table with all output types combined.
#' @export
load_daisy_outputs <- function(
  dir,
  required_outputs = "all",
  sims_to_load = "all",
  combine_results = FALSE
) {
  if (!dir.exists(dir)) {
    stop("Directory doesn't exist.", call. = FALSE)
  }

  all_files <- list.files(
    path = dir,
    pattern = "\\.dlf$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(all_files) == 0) {
    stop("No .dlf files found in directory.", call. = FALSE)
  }

  file_names <- basename(all_files)
  unique_outputs <- unique(file_names)

  outputs_to_load <- if (identical(required_outputs, "all")) {
    unique_outputs
  } else {
    intersect(unique_outputs, paste0(required_outputs, ".dlf"))
  }

  if (length(outputs_to_load) == 0) {
    stop("None of the requested output types were found.", call. = FALSE)
  }

  files_to_load <- all_files[file_names %in% outputs_to_load]

  # Keep only requested simulations
  if (!identical(sims_to_load, "all")) {
    sim_ids <- basename(dirname(dirname(files_to_load)))

    files_to_load <- files_to_load[sim_ids %in% sims_to_load]

    if (length(files_to_load) == 0) {
      stop("None of the requested simulations were found.", call. = FALSE)
    }
  }

  files_split <- split(files_to_load, basename(files_to_load))

  file_types <- file_path_sans_ext(names(files_split))
  results <- vector("list", length(files_split))
  names(results) <- file_types

  message(
    "Loading required Daisy outputs for ",
    length(files_to_load) / length(files_split),
    " simulations..."
  )

  for (i in seq_along(files_split)) {
    file_type <- file_types[i]
    type_files <- files_split[[i]]

    message(
      "Processing output ",
      i,
      " of ",
      length(files_split),
      ": ",
      file_type
    )

    # Read header once per file type
    header_dt <- fread(
      file = type_files[1],
      skip = "--------------------",
      nrows = 1,
      showProgress = FALSE
    )
    col_names <- names(header_dt)

    # Read each file and add sim identifier
    read_output <- function(file_path) {
      sim_id <- basename(dirname(dirname(file_path)))

      dt <- fread(
        file = file_path,
        skip = "--------------------",
        header = TRUE,
        showProgress = FALSE
      )

      # Drop units row
      dt <- dt[-1]

      set(dt, j = "sim_id", value = sim_id)
      dt
    }

    # Parallel not suitable here due to overhead and small file sizes; reading sequentially is more efficient
    dt_list <- lapply(type_files, read_output)

    all_data <- rbindlist(dt_list, use.names = TRUE)

    # Type conversion for all columns except 'sim_id'
    cols <- setdiff(names(all_data), "sim_id")
    for (col in cols) {
      set(
        all_data,
        j = col,
        value = type.convert(all_data[[col]], as.is = TRUE)
      )
    }

    setnames(
      all_data,
      make_clean_names(names(all_data))
    )

    if (all(c("year", "month", "mday") %in% names(all_data))) {
      all_data[, date := as.Date(sprintf("%04d-%02d-%02d", year, month, mday))]
    }

    results[[i]] <- all_data
  }

  message("Successfully loaded ", length(results), " file type(s).")

  if (combine_results) {
    # Check all list items have same number of rows
    n_rows <- vapply(results, nrow, integer(1))

    if (!all(n_rows == n_rows[1])) {
      stop(
        "Can't combine data frames: rows counts differ. Select different outputs or set combine_results = FALSE."
      )
    }

    # Merge list items into one dataframe
    combined_results <- Reduce(
      function(x, y) cbind(x, y),
      results
    )

    combined_results <- combined_results[,
      !duplicated(names(combined_results)),
      with = FALSE
    ]

    invisible(combined_results)
  } else {
    invisible(results)
  }
}
