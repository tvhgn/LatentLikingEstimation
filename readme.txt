# Contents
This folder has three directories:

- 'data':       contains directories for each participant. Each participant directory contains behavioral data files relevant for the estimation of the latent liking scores and for testing the model's validity.

- 'scripts':    contains scripts for pre-processing, running the JAGS model to estimate latent liking scores, checking the validity of the model (predictive validity, k-fold-validation), and running the final analysis (includes figure generation).

- 'results:     contains the figures resulting from the model analysis. Further contains participant directories with data on the pre-mri liking scores, latent liking scores, and final ranking scores. These resulted from the model analysis as well.


# How to start
- Open the scripts folder, and open the main_script.R file. Make sure to change the working directory to the level of the scripts folder.
- Run the scripts from each step one after another.
- Step 3 and, especially, step 5 take a long time to run (potentially 2 hours). Be sure to make time for that. The resulting data is stored after running, so on subsequent inquiries you can opt to load these in your environment, instead of re-running these steps.
- Check the codebook for further information on each variable used in the scripts.
