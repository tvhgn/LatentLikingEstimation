# Library imports
library(dplyr)                                                
library(readr)
library(readxl)
library(writexl)

# Load functions
source(file.path("utils","jags_functions.R"))

#### Get data file paths across all subjects ####
# Location of data files
data_path <- file.path("..", "data") # using file.path to make it platform independent

# location for storing the datasets
datasets_var_path <- file.path("varstore", "datasets.RData")
matrices_var_path <- file.path("varstore", "matrices.RData")
ranking_var_path <- file.path("varstore", "ranking_data.RData")
rating_var_path <- file.path("varstore", "rating_data.RData")

# Get subject directories
subject_dirs <- list.dirs(data_path, recursive=FALSE)
subject_dirs_rel <- list.dirs(data_path, full.names = F, recursive = F) # just subject names
n_subjects <- length(subject_dirs) # total number of subjects

#### Pre-processing and preparation of the behavioral dataset ####
datasets <- list()

# Loop across participants
for (i in 1:n_subjects){
  # Initialize list which will contain datafiles for this specific participant
  sub_beh_data <- list()
  
  # Path for subject's folder containing behavioral data collected during MRI runs
  sub_data_path <- file.path(subject_dirs[i], "mri_runs_behavioral")
  
  # Within folder list all datafiles (one .csv file per run)
  sub_data_files <- list.files(path = sub_data_path, full.names = TRUE)
  n_runs <- length(sub_data_files)
  
  # Initialize empty list
  temp_all_data <- list()
  # Read datafiles and combine into single dataframe
  for (j in 1:length(sub_data_files)){
    # Read the CSV file
    data <- read.csv(sub_data_files[j])
    # append data to temporary container list
    temp_all_data <- append(temp_all_data, list(data))
  }
  
  # Combine all separate runs into one single dataframe
  sub_all_data <- do.call(rbind, temp_all_data)

  
  # Remove jittered trials (that are missing values in cat1 or cat2)
  last_col <- ncol(sub_all_data)
  sub_all_data <- sub_all_data[sub_all_data[, last_col]!= "" & sub_all_data[, (last_col-1)]!="", ]
  
  # Store in list for all participants
  new_subject <- subject_dirs_rel[i]
  datasets[[new_subject]] <- sub_all_data
  
}

#### Pre-processing and preparation of the data matrices #### (these will serve as input for the JAGS model)
matrices <- list() # initialize list
for (i in 1:n_subjects){
  subject <- subject_dirs_rel[i]
  sub_dataset <- datasets[[subject]]
  matrices[[subject]] <- create_matrices(sub_dataset) # reusable function from utils/jags_functions.R
}


#### Pre-processing of pre- and post mri liking information (for use in validation script) ####
true_ranks_subs <- list() # Initialize list that contains 'true' ranking data for all subjects, which is the final ranking
ratings <- list() # initialize list that will contain pre-mri rating data per subject

for (i in 1:n_subjects){
  # subject id
  subject <- subject_dirs_rel[i]
  # Location of ranking data
  ranking_file <- file.path(subject_dirs[i], "final_ranking", "post_mri_ranking.xlsx")
  
  # Read datafile
  ranking_data <- read_excel(ranking_file)
  
  # Extract ranking vector, which is a sequence of painting ID's, ranked from highest to lowest rank
  true_ranks_vec <- ranking_data$MRI_code 
  
  # Drop all columns but MRI_code and rank, sort by MRI_code, rename columns to ID and Ranking, and convert to data.frame
  ranking_data <- ranking_data %>%
    select(MRI_code, rank) %>%
    arrange(MRI_code) %>%
    rename(ID=MRI_code, Ranking=rank) %>%
    as.data.frame()
  
  ranking_entry <- list(data=ranking_data, ranking_vector=true_ranks_vec)
  true_ranks_subs[[subject]] <- append(true_ranks_subs[[subject]], ranking_entry)
  
  # Get pre-mri ratings
  rating_file <- file.path(subject_dirs[i], "pre_mri_rating", "pre_mri_rating.xlsx")
  rating_data <- read_excel(rating_file) %>%
    select(Label, liking_scores) %>%
    rename(MRI_code=Label)
  
  ratings[[subject]] <- rating_data
}


# Store datasets
save(datasets, file=datasets_var_path) 
save(matrices, file=matrices_var_path)
save(true_ranks_subs, file=ranking_var_path)
save(ratings, file=rating_var_path)
