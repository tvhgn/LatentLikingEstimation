# Import
library(R2jags)
library(runjags)

# Initialize list variable which will contain outputs across subjects
jags_output_subs <- list()

# set seed
set.seed(1234)

# iterate over subject
for (i in 1:n_subjects){
  # Pick subject and create string object
  subject <- subject_dirs_rel[i]

  # Print status message
  print(paste("Running JAGS for:", subject))

  # Retrieve subject's data matrices, which will be used as input data.
  M_pref <- matrices[[subject]]$M_pref
  M_n <- matrices[[subject]]$M_n



  # Prepare the data
  dataList <- list(y = M_pref,
                   n = M_n,
                   nPaintings = 36)

  # Model parameters
  pars <- c("liking")
  samples <- 10000
  burnin <- 1000
  nAdapt <- 1000

  output <- run.jags(model="models/ranking_logregres_bin_reparam.txt",
                     monitor=pars,
                     data=dataList,
                     n.chains = nChains,
                     inits=inits,
                     burnin=burnin,
                     sample=samples,
                     adapt=nAdapt,
                     method="rjparallel"
  )

  # Store outputs
  jags_output_subs[[subject]] <- output
  # Summary
  print(output)
}

# Save the data to local variable
save(jags_output_subs, file=file.path("varstore", "jags_output_all_subs.RData"))