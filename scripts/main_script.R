# Step 1: Preprocess MRI collected behavioral data 
source("1_preprocessing.R")

# Step 2: Setup JAGS model and initialize settings
source("2_JAGS_setup_initialization.R")

# Step 3: Run JAGS model to estimate latent liking scores per subject (this will take time)
source("3_JAGS_run_estimation.R")

# Step 4: Run predictive validity check.
source("4_predictive_validity.R")

# Step 5: Run K-Fold Validation (this will take more time)
source("5_k_fold_validation.R")

# Step 6: Analyze and visualize results
source("6_analysis_and_visualization.R")
