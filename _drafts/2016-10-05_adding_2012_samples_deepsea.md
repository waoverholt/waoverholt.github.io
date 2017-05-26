---
layout: post
title: Large-scale OTU picking with SWARM (SUCCESS!)
excerpt: "Successfully picking OTUs using the SWARM algorithm on a large diverse set of 16S amplicons."
---

* Table of Contents

{:toc}

I noticed I was missing several cores from 2012 in my final all_kostka_seqs.trim.fasta dataset. I'm going to work on recovering those.

Taking from my work computer.
/data/home/woverholt3/Projects/Deep-C/DeepC_Seq_analysis/all_gom_seqs/raw_seqs/MSU_DeepC_5_plates/ANL_9-9-13/only_deepc_seqs.fna

Tranferring to the biocluster.

Picking OTUs against my reference sequences to avoid re-running everything again.
{% highlight bash %}
#PBS -N qiime_parallel_uclust_ref_SILVA
#PBS -l nodes=1:ppn=12
#PBS -l mem=40gb
#PBS -l walltime=24:00:00
#PBS -q biocluster-6
#PBS -j oe
#PBS -o job_output_files/out.uclust_ref_otus_20161005
#PBS -m abe
#PBS -M waoverholt@gmail.com

export WORKON_HOME=$HOME/data/program_files/VirtualEnvs
source $HOME/.local/bin/virtualenvwrapper.sh 

workon qiime1.9.1
module load R/3.2.2

INPUT=/nv/hp10/woverholt3/data/qiime_files/all_gom_seqs/missing_2012_sample_sequences/only_deepc_seqs.fna
OUTPUT=/nv/hp10/woverholt3/data/qiime_files/all_gom_seqs/missing_2012_sample_sequences/uclust_ref_otus
REF=/nv/hp10/woverholt3/data/qiime_files/all_gom_seqs/swarm_full_dataset/rep_set_mc2_s50.fa

parallel_pick_otus_uclust_ref.py -i $INPUT -o $OUTPUT -z -O 12 -r $REF
{% endhighlight %}

I had 3196970 failures out of 13876890 input sequences (77% retention).

