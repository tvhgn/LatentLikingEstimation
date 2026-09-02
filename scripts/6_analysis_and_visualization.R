# Necessary imports
library(papaja)
library(writexl)
library(ggplot2)
library(bayestestR)
library(scales)
library(ggpubr)
library(effectsize)
library(stringr)
library(tidyr)

# Create folder for data and figure storage
figures_path <- file.path("..", "results", "figures")
ifelse(!dir.exists(figures_path),
       dir.create(figures_path),
       "Directory Exists")

#### Predictive validity ####

# Correlations across stages
df_ranked <- liking_stages_df %>%
  # filter(Subject != "sub-n23" & Subject != "sub-n12") %>% # filter outliers
  group_by(Subject) %>%
  mutate(Rating_Score=rank(-Rating_Score),
         Latent_Score=rank(-Latent_Score))

cor_rat_ranked <- cor.test(df_ranked$Rating_Score, df_ranked$Ranking_Score,
                           method = 'spearman')
cor_rat_latent <- cor.test(df_ranked$Rating_Score, df_ranked$Latent_Score,
                           method = 'spearman')
cor_lat_ranked <- cor.test(df_ranked$Latent_Score, df_ranked$Ranking_Score,
                           method = 'spearman')


# Convert to long format
liking_stages_long <- liking_stages_df %>%
  pivot_longer(cols=3:5, names_to = "liking_stage", values_to = "score") %>%
  mutate(
    liking_stage = case_match(liking_stage,
                              "Rating_Score"~"Rating",
                              "Latent_Score"~"Latent",
                              "Ranking_Score"~"Ranking")
  ) %>%
  mutate(liking_stage = factor(liking_stage,
                               levels=c("Rating", "Latent", "Ranking")))



# violin plot
liking_stages_long %>% filter(liking_stage!="Ranking") %>%
  ggplot(aes(x=liking_stage, y = score, fill=liking_stage)) +
  geom_violin() +
  geom_jitter(width=0.05, height=0.2, alpha=0.1) +
  theme_classic()

# Create long format of dataframe
cor_samples_long <- cor_samples_df %>%
  select(-"sub.e01") %>%
  pivot_longer(cols=starts_with("sub-"),
               names_to="Subject",
               values_to="Sample_r") %>%
  mutate(Subject= factor(Subject))

# Get the average correlation
mean_corr <- mean(cor_samples_long$Sample_r)
cor_samples_no_outliers <- 
  cor_samples_long %>% filter(Subject!= "sub-n23" & Subject!= "sub-n12")

mean(cor_samples_no_outliers$Sample_r)

# Create plot using ggplot
pred_val_plot <- ggplot(cor_samples_long, aes(x=Sample_r, colour=Subject, fill=Subject)) +
  geom_density(alpha = 0.4, color=NA) +
  #geom_vline(aes(xintercept = mean_corr), color='red', linewidth = 1, linetype = 'dashed') +
  xlab("Correlation with Final Ranking") +
  ylab("Density") +
  theme_classic() +
  theme(legend.position = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme(
    axis.title = element_text(size = 16),     # Change axis title size
    axis.text = element_text(size = 14)) 

ggsave(filename = "predictive_validity.png", plot=pred_val_plot, path = figures_path, units = "px", dpi = 300)
# Summary df
cor_summary <- cor_samples_long %>%
  group_by(Subject) %>%
  summarise(mean = mean(Sample_r),
            sd = sd(Sample_r))

# Inspect outliers
liking_stages_outliers <- df_ranked %>%
  filter(Subject == "sub-n23" | Subject == "sub-n12") %>%
  group_by(Subject) %>%
  summarize(cor_rat_lat = cor(Rating_Score, Latent_Score),
            cor_lat_rank = cor(Latent_Score, Ranking_Score),
            cor_rat_rank = cor(Rating_Score, Ranking_Score))

#### K-fold validation ####
# Test mean accuracy for significance
mean_k_fold_acc <- mean(df_k_fold_acc$Accuracy)
# check for significance
t.test(df_k_fold_acc$Accuracy, mu=0.5)
# Get effect size
cohens_d(df_k_fold_acc, Accuracy~1, mu=0.5)

# Plot histogram of accuracies 
k_fold_plot <- df_k_fold_acc %>% ggplot(aes(x=Accuracy)) +
  geom_histogram(binwidth = 0.025, color='black', fill='cyan') +
  #geom_density(aes(y=after_stat(density) * nrow(df_k_fold_acc) * 0.025), color='red') +
  geom_vline(aes(xintercept = mean_k_fold_acc), color='red', linetype = 'dashed', linewidth = 1) +
  theme_classic() +
  ylab("Number of Observations") +
  xlab("Prediction Accuracy") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  theme(
    axis.title = element_text(size = 16),     # Change axis title size
    axis.text = element_text(size = 14)) 

# Store figures
ggsave(filename = "k_fold_validation_plot.png", plot=k_fold_plot, path=figures_path, units="px", dpi=300)
fig_arranged <- ggarrange(pred_val_plot, k_fold_plot,
          labels=c("A", "B"), font.label= list(size=16))
ggsave(plot = fig_arranged, filename = "pred_and_kfold_validation.png", path=figures_path, units="px", dpi=300)
