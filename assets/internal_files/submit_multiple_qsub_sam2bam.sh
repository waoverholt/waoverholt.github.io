#!/bin/bash
INDIR=~/kostka-dir/Will_testing-metagenome-assemblers/DeepC_Metagenomes_Mason/trimmed2/size_filtered/paired_ends/CoupledReads/fasta_files

for FILE in $(find $INDIR -type f -name "*sam");
do
    qsub -v INFILE=$FILE /nv/hp10/woverholt3/job_scripts/metagenome_scripts/multiple_qsub_sam2bam.pbs
done

