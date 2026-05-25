# idaisy

## Installation
Install using the following command in R:

```pak::pak("RyanD956/idaisy")```

## Folder structure
The recommended folder structure for using iDaisy is:

```
root/lib_files
root/projects
root/R
```

- `lib_files`: This folder contains custom library files for running daisy simulations.
- `projects`: This folder is where you will create subfolders for each of your daisy simulation projects. Each project folder contain its own input files, output files, and scripts.
- `R`: This folder is where you can store your R scripts to run simulations, process results, and perform analyses.

## Creating a new daisy project
To create a new daisy project, you can use the `create_daisy_project` function.
This creates a new project folder within the `projects` directory, along with the necessary subfolders and files to get started with your daisy simulation.

```
library(idaisy)
create_daisy_project(dir = "my_daisy_project")
```

This creates the following folders:

```
my_daisy_project/inputs
my_daisy_project/outputs
my_daisy_project/simulations
```

- `inputs`: This folder is where you can place your input files for the daisy simulations, such as parameter tables and template files.
- `outputs`: This folder is where the final results of your daisy simulations can be saved.
- `simulations`: This folder is where the generated scripts for running your daisy simulations (as well as the raw outputs and log files) will be stored.

## Creating simulations
To create simulations within your daisy project, you can use the `create_daisy_scripts` function. This function takes a dataframe of parameters and a template file to generate the necessary scripts for running your simulations. This is not necessary (you can also manually create your own scripts), but it can help automate the process of setting up simulations based on a structured input.

A template file is a daisy script (.txt file) with `{{}}` placeholders that can be filled in with specific parameters from a dataframe. The dataframe must have a column called `sim_name`.
For example, if you have a dataframe (e.g. an excel file) with columns `sim_name`, `weather_file`, `soil_column`, `plough_date`, `sow_date` and `crop_model` you can create a template file with the following content:

```
[previous daisy code]

; Set the weather file
(weather default "{{weather_file}}.dwf")

; Initialise the soil column
(defcolumn "soil_column" "{{soil_column}}")
(column soil_column)

; Management program for this year
(defaction "current_year" activity
  (wait_mm_dd {{plough_date}})
  (plowing)

  (wait_mm_dd {{sow_date}})
  (sow "{{crop_model}}")
)

[remaining daisy code]
```

This will then generate a new daisy script for each row of your dataframe, inserting the parameters from the relevant columns. This allows you to easily generate many daisy scripts with different parameter combinations. Since this works with any dataframe, you can import an excel file with parameters but also generate a dataframe within R and use that to create the scripts.

To create the scripts for your simulations, you can use the following code:

```
library(idaisy)
library(readxl)

template_path <- "root/projects/my_daisy_project/inputs/template.txt"
df_path <- "root/projects/my_daisy_project/inputs/parameters.xlsx"

# Load dataframe
df <- read_excel(
  df_path,
  skip = 1
)

# Create daisy scripts
create_daisy_scripts(
  df = df,
  dir = "root/projects/my_daisy_project/simulations",
  template_path = template_path
)
```

This creates a subfolder in root/projects/my_daisy_project/simulations named after the `sim_name` column in the dataframe. When the simulation is run, the log file is available in this folder and outputs in root/projects/my_daisy_project/simulations/sim_name/outputs.

## Running simulations
To run the simulations, you can use the `run_daisy_simulations` function. This function takes the directory, finds all .dai files recurseively, and then runs each daisy script, saving the outputs and log files in the relevant folders. You can run all scripts or a subset, in parallel or in sequence.

```
library(idaisy)

run_daisy_scripts(
  dir = "root/projects/my_daisy_project/simulations",
  sims_to_run = "all",
  parallel = TRUE
)
```

## Collating outputs
To collate the outputs from your simulations, you can use the `load_daisy_outputs` function. This function takes the simulation directory, finds all .dlf files recursively, extracts the relevant outputs and collates them into a list of dataframes for analysis.

```
library(idaisy)

data_list <- load_daisy_outputs(
  dir = "root/projects/my_daisy_project/simulations",
  required_outputs = "all"
)

# Collapse into a single dataframe
model_data <- data_list %>%
  reduce(~ bind_cols(.x, .y, .name_repair = "minimal")) %>%
  select(which(!duplicated(names(.))))

# Save collated output
write.csv(
  model_data,
  "root/projects/my_daisy_project/outputs/my_daisy_project_results.csv"
  row.names = FALSE
)
```