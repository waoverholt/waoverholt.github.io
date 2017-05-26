#!/bin/bash
INDEX=~/kostka-dir/Will_testing-metagenome-assemblers/megahit_full_clean/clean_samps
INDIR=~/kostka-dir/Will_testing-metagenome-assemblers/DeepC_Metagenomes_Mason/trimmed2/size_filtered/paired_ends/CoupledReads/fasta_files

while read LINE; do
    INFILE=$INDIR/$LINE;
    OUTFILE=$INDIR/$LINE".sam";
    echo $OUTFILE;
    qsub -v INDEX=$INDEX,INSEQ=$INFILE,OUTFILE=$OUTFILE $HOME/job_scripts/metagenome_scripts/multiple_qsub_subsample.pbs;
done < ~/kostka-dir/Will_testing-metagenome-assemblers/DeepC_Metagenomes_Mason/trimmed2/size_filtered/paired_ends/CoupledReads/fasta_files/list_clean_samps.txt
