---
layout: post
title: "Attemping to use Rmpi to parallelize a model"
excerpt: "temp"
---

* Table of Contents

{:toc}

I'm following the tutorial [here](http://www.glennklockwood.com/data-intensive/r/on-hpc.html).

## Installing Rmp
{% highlight bash %}
module load R/3.2.2
module load gcc/4.7.2
module load openmpi/1.8

cd ~/data/program_files
wget https://cran.r-project.org/src/contrib/Rmpi_0.6-6.tar.gz

R CMD INSTALL --configure-vars="CPPFLAGS=-I$MPIHOME/include LDFLAGS='-L$MPIHOME/lib'" --configure-args="--with-Rmpi-include=$MPIHOME/include \
--with-Rmpi-libpath=$MPIHOME/lib \
--with-Rmpi-type=OPENMPI" -l ~/data/program_files/R_libs/ Rmpi_0.6-6.tar.gz
{% endhighlight %}


# This didn't work at all, issues with the slaves running correctly and inheriting from openMPI

# Doing this the hard way
split the otu_mods into 20 chunks and saving them as .RDS
{% highlight R %}
otu_mods <- readRDS("otu_mods_nolowvar.rds")
chunk2 <- function(x,n) split(x, cut(seq_along(x), n, labels = FALSE))
ind_mods <- chunk2(otu_mods, 100)
for (i in 1:length(ind_mods)) {saveRDS(ind_mods[[i]], file=paste(i,".rds",sep=''))}

{% endhighlight %}

Then I used 3 scripts to process the 20 submodels on the biocluster
Rscript (parallelizing_otu_model.R):
{% highlight R %}
library(plyr)
library(randomForest)

args = commandArgs(trailingOnly = T)
setwd("~/data/temp_R_work/deep_otu_model_work")

melt_model_otu_table <- readRDS(file="merge_melt_mason_kostka_otu_test_model.rds")
otu_mod_chunk <- readRDS(paste(args[1],'.rds', sep=''))
list_otu_chunk <- names(otu_mod_chunk)

melt_chunk <- melt_model_otu_table[which(melt_model_otu_table$OTUID %in% list_otu_chunk),]

pred_chunk <- adply(melt_chunk, 1, function(x) predict(otu_mod_chunk[[paste(x$OTUID)]], newdata = x))


write.table(pred_chunk, sep="\t", file=paste(args[1],'_pred.txt',sep=''), quote=F, row.names = F)
{% endhighlight %}

PBS Script for scheduler (multiple_qsub_Rscript_v2.pbs)
{% highlight bash %}
#PBS -N multiple_Rscript
#PBS -l nodes=1:ppn=1
#PBS -l mem=30gb
#PBS -l walltime=08:00:00
#PBS -q iw-shared-6
#PBS -j oe
#PBS -o $HOME/job_output_files/out.multple_Rscript.${PBS.JOBID}
#PBS -m e
#PBS -M waoverholt@gmail.com

module load R/3.2.2

Rscript $HOME/data/temp_R_work/deep_otu_model_work/parallelizing_otu_model.R ${ITERATION}
{% endhighlight %}

Bash script to submit multiple submissions (submit_multiple_qsub_Rscript_v2.sh)
{% highlight bash %}
#!/bin/bash

for i in `seq 1 20`;
do
    qsub -v ITERATION=$i $HOME/job_scripts/multiple_qsub/multiple_qsub_Rscript.pbs
done
{% endhighlight %}

Then use bash to merge all the chunks back into one table.
{% highlight bash %}
cat 1_pred.txt > pred_otu_table_fullsampleset.txt
mv 1_pred.txt 1_prd.txt
ls | grep -E "[0-9]+\_pred.*" | xargs -I file tail -n +2 file >> pred_otu_table_fullsampleset.txt
{% endhighlight %}