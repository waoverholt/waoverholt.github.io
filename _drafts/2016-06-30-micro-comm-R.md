

R_project = ~/Projects/Deep-C/DeepC_Seq_analysis/all_gom_seqs/full_set_swarm_20162906/R_work/

Steps done so far:
Initializing_all_input.R
* Normalize using metagenomeSeq(v1.8.3)
.* only included samples with >5000 observations
.* p set at default quartile
.* norm = T, log = F, sl=1000


Importing QIIME distance matrices does not work with this command:
wunifrac_dist <- as.dist(read.table(file="../beta_div/weighted_unifrac_final_otutable_mc2_s50.txt"))

