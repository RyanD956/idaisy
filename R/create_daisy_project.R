#' Create a new Daisy project directory structure
#' @param dir The parent directory for your project
#' @export
create_daisy_project <- function(dir) {
  if (dir.exists(dir)) {
    stop(
      "Project directory already exists. Choose a different name or remove the existing directory."
    )
  }

  message("Creating project directory...")
  dir.create(dir, recursive = TRUE)

  message("Creating project folders...")
  dir.create(file.path(dir, "inputs"))
  dir.create(file.path(dir, "outputs"))
  dir.create(file.path(dir, "simulations"))
  dir.create(file.path(dir, "data"))
  dir.create(file.path(dir, "R"))

  message("Project structure created at: ", dir)
}
