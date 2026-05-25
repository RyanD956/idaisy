#' Run Daisy simulations in a specified directory, optionally in parallel.
#' @importFrom furrr future_walk
#' @importFrom future plan availableCores multisession
#' @importFrom withr with_dir
#' @importFrom tools file_path_sans_ext
#' @param dir Directory containing Daisy simulation .dai files. The function will search for .dai files in all subdirectories. Note the output directory is defined in the daisy file (log_prefix) and must exist. Function assumes this is /outputs within each simulation folder and so creates this folder.
#' @param sims_to_run A character vector of simulation names to run, e.g.c("sim1", "sim2"). If "all", all .dai files found in the directory will be run.
#' @param daisy_exe The file path to the daisy executable. Defaults to "C:/Program Files/daisy 7.1.0/bin/daisy.exe". Update this if your daisy installation is in a different location.
#' @param parallel Whether to run simulations in parallel using available CPU cores. Defaults to TRUE.
#' @return Invisibly returns a character vector of the .dai file paths that were run.
#' @export
run_daisy_scripts <- function(
  dir,
  sims_to_run = "all",
  daisy_exe = "C:/Program Files/daisy 7.1.0/bin/daisy.exe",
  parallel = TRUE
) {
  if (!dir.exists(dir)) {
    stop("Directory doesn't exist.", call. = FALSE)
  }

  if (!file.exists(daisy_exe)) {
    stop("Daisy executable not found.", call. = FALSE)
  }

  # Collect all .dai files under dir
  all_files <- list.files(
    path = dir,
    pattern = "\\.dai$",
    recursive = TRUE,
    full.names = TRUE
  )

  # Filter to requested simulations
  files_to_run <- if (identical(sims_to_run, "all")) {
    all_files
  } else {
    all_files[file_path_sans_ext(basename(all_files)) %in% sims_to_run]
  }

  if (length(files_to_run) == 0) {
    stop("No matching .dai files found to run.", call. = FALSE)
  }

  # Warn about any requested simulations that could not be matched
  if (!identical(sims_to_run, "all")) {
    matched <- file_path_sans_ext(basename(files_to_run))
    missing <- setdiff(sims_to_run, matched)
    if (length(missing) > 0) {
      warning(
        "Could not find .dai files for: ",
        paste(missing, collapse = ", "),
        call. = FALSE
      )
    }
  }

  # Create output directories
  for (f in files_to_run) {
    dir.create(
      file.path(dirname(f), "outputs"),
      recursive = TRUE,
      showWarnings = FALSE
    )
  }

  # Run a single simulation, checking the exit code
  run_file <- function(file_path) {
    script <- basename(file_path)
    wd <- dirname(file_path)

    # Capture and check exit code — Daisy may fail silently otherwise
    status <- with_dir(
      wd,
      system2(command = daisy_exe, args = shQuote(script), stdout = NULL)
    )

    if (!is.null(status) && status != 0L) {
      warning(
        "Daisy returned non-zero exit code (",
        status,
        ") for: ",
        script,
        call. = FALSE
      )
    }

    invisible(status)
  }

  message(
    "About to run ",
    length(files_to_run),
    " file(s)",
    if (parallel) " in parallel." else " in sequence."
  )

  if (parallel) {
    n_workers <- max(1L, availableCores() - 2)
    message(
      "Running in parallel with ",
      n_workers,
      " of ",
      availableCores(),
      " available cores."
    )

    # Capture old plan when setting the new one
    old_plan <- plan(multisession, workers = n_workers)
    on.exit(plan(old_plan), add = TRUE)

    future_walk(files_to_run, run_file, .progress = TRUE)
  } else {
    for (i in seq_along(files_to_run)) {
      message(
        "Running simulation ",
        i,
        " of ",
        length(files_to_run),
        ": ",
        basename(files_to_run[i])
      )
      run_file(files_to_run[i])
    }
  }

  message("Finished running ", length(files_to_run), " simulations.")
  message("Check 'daisy.txt' in each simulation folder for logs if needed.")
  if (parallel) {
    message("If issues persist, try re-running in sequence (parallel = FALSE).")
  }

  # Return paths invisibly for chaining / inspection
  invisible(files_to_run)
}
