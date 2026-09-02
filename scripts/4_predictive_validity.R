# Necessary imports
library(R2jags)
library(runjags)
library(writexl)
library(bayestestR)
library(tidyr)

# initialize variables
subs_validity <- list()
#subs_validity_test <- list()
n_samples <- jags_output_subs$`sub-e01`$sample * nChains
cor_samples_df <- data.frame("sub-e01"=rep(NA, n_samples)) # will contain correlations across model samples
liking_stages_df <- matrix(NA, 
                           nrow = n_subjects*36,
                           ncol = 5) # Contains liking scores from all three stages

# Create folder for data and figure storage
results_dir <- file.path("..", "results")
ifelse(!dir.exists(results_dir),
       dir.create(results_dir),
       "Directory Exists")

ifelse(!dir.exists(file.path(results_dir, "figures")),
       dir.create(file.path(results_dir, "figures")),
       "Directory Exists")

# Loop across subjects
for (i in 1:n_subjects){
  # string object for picking subject
  subject_string <- subject_dirs_rel[i]
  # Extract MCMC samples for latent ranks
  liking_samples <- combine.mcmc(jags_output_subs[[subject_string]])
  # Calculate correlation for each MCMC sample with the ranking task data. This is a measure of predictive validity.
  cor_samples <- apply(liking_samples, 1, 
                       function(x) cor(rank(-x),
                                       true_ranks_subs[[subject_string]]$data$Ranking, 
                                       method='spearman')) # Reverse rank (higher liking scores correspond to higher ranks. In other words, they are closer to rank 1)
  
  # start and end indices depends on subject number
  i_start <- (i-1)*36 + 1
  i_end <- i_start + 35
  # Enter subject number and painting ID
  liking_stages_df[i_start:i_end, 1] <- subject_string
  liking_stages_df[i_start:i_end, 2] <- 1:36
  # Extract and store ratings
  subject_rating <- ratings[[subject_string]]$liking_scores
  liking_stages_df[i_start:i_end, 3] <- subject_rating
  # Extract latent liking scores and store
  subject_latent <- as.numeric(jags_output_subs[[subject_string]]$summary$statistics[,'Mean'])
  liking_stages_df[i_start:i_end, 4] <- subject_latent
  # Extract rankings and store
  subject_ranking <- true_ranks_subs[[subject_string]]$data$Ranking
  liking_stages_df[i_start:i_end, 5] <- subject_ranking
  
  # Create csv file with data on subject
  df_subject <- data.frame(
    label = 1:36,
    rating = subject_rating,
    latent_liking = subject_latent,
    ranking = subject_ranking
  )

  save_liking_path <- file.path(results_dir, subject_string, "liking_three_stages.xlsx")
  
  # Create directory if necessary
  ifelse(!dir.exists(file.path(results_dir, subject_string)),
         dir.create(file.path(results_dir, subject_string)),
         "Directory Exists")
  # Write csv file
  write_xlsx(df_subject, path=save_liking_path)
  
  # Store in dataframe
  cor_samples_df[subject_string] <- cor_samples
  
  # Summarize the posterior distribution of the correlations
  # First get median values
  median_r <- median(cor_samples)
  # Get highest density interval
  HDI <- hdi(cor_samples)
  # store into list
  HDI_data <- list(median=median_r,
                   HDI.L=as.numeric(HDI)[2],
                   HDI.H=as.numeric(HDI)[3])
  
  
  # Store data to list variable
  subs_validity[[subject_string]] <- HDI_data
}

# Transform liking scores matrix to dataframe, add column names, and factorize
liking_stages_df <- as.data.frame(liking_stages_df)
colnames(liking_stages_df) <- c("Subject", "PaintID", "Rating_Score", "Latent_Score", "Ranking_Score")
liking_stages_df <- liking_stages_df %>%
  mutate(Subject = factor(Subject),
         PaintID = factor(PaintID),
         Rating_Score = as.numeric(Rating_Score),
         Latent_Score = as.numeric(Latent_Score),
         Ranking_Score = as.numeric(Ranking_Score))

