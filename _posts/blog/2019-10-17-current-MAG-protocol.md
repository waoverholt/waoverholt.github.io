---
layout: post
title: Draft Protocol for Assembling MAGs from Complex Metagenomes
image:
  teaser: shrug.png
excerpt: "My latest workflow for QAQC, assembly, binning, taxnomic annotation, and functional annotation of environmental metagenomes. It is still in draft form and I'm getting all the pipeline/nextflow scripts together."
---
* Table of Contents
{:toc}

The example files & paths shown throughout this workflow are on the Kuesel Labs server LUMOS. I've set up all the conda environments necessarily already and I don't go into that process here.

I've been testing this protocol on a collection of small test metagenomes. The working directory for these examples is here:

/home/user/data/Projects/example_metaGs/scripts

## QAQC

In this step we are removing all the adapter sequences, as well as trimming of low quality sequences (phred = 20), and dropping sequences that are shorter than 50 bp. See the parameters that are set below.

Here I'm using bbduk from the JGI BBTools suite.

I'm putting everything into a "nextflow" script which is found here on the server:
/home/user/data/Projects/example_metaGs/scripts/01_metaG_qaqc_bbduk.nf

And [here]({{ site.url }}/assets/internal_files/01_metaG_qaqc_bbduk.nf) on this site.

I'm not very comfortable with nextflow yet, so I wasn't able to get a complete pipeline that would automatically run all the steps. But I have found it to be extremely useful for controlling the servers resources (e.g. running things in parallel in the most effective ways).

The bbduk command that is being run:
```bash
bbduk.sh -Xmx1g \
    in1=${reads[0]} \
    in2=${reads[1]} \
    out1=${reads[0].baseName} \
    out2=${reads[1].baseName} \
    stats=${pair_id}.stats.txt \
    ref=$ADAPTERS \
    threads=${task.cpus} \
    ktrim=r \
    qtrim=rl \
    trimq=20 \
    minlen=50 \
    k=23 \
    mink=11 \
    hdist=1 \
```

The nextflow script can be run with:
```bash
conda activate metagenomics
nextflow run path/to/script/metaG_qaqc_bbduk.nf
```

## Assembly
Here I'm using the metagenome setting within [spades](http://cab.spbu.ru/software/spades/)

This example is for illumina only datasets, running each sample individually & manually

```bash
conda activate metagenomics
spades.py --meta -o spades_miseq_02frac -1 02_qaqc/H41_0_1_1_1.fastq -2 02_qaqc/H41_0_1_1_2.fastq -t 10 -m 350 --tmp-dir ~/scratch/
```

I also have a hacked together nextflow script that parallelizes this step in case you have multiple samples.
```bash
cd /home/user/data/Projects/example_metaGs
nextflow run -c scripts/spades_nextflow.config scripts/02_spades_nextflow.nf
```
[Script]({{ site.url }}/assets/internal_files/02_spades_nextflow.nf)

[config]({{ site.url }}/assets/internal_files/spades_nextflow.config)

I recommend using [Metaquast](http://bioinf.spbau.ru/metaquast) to assess your assembly quality
```bash
metaquast -o metaquast_out -1 02_qaqc/H41_0_1_1_1.fastq -2 02_qaqc/H41_0_1_1_2.fastq path/to/scaffolds.fasta -t 8
```

I do not have a nextflow script for this yet, let me know if you want one. This one I can probably combine with the assembly script so that everything is done at once...

## Binning

Here I like to use 3 different automatic binners, 2 of which are already included in the [metawrap](https://github.com/bxlab/metaWRAP) pipeline and the 3rd [binsanity](https://github.com/edgraham/BinSanity) that I run separately.

### Metawrap
It depends a bit on your data and your own preferences, but I usually drop scaffolds that are shorter than 1000 bp for these binners.

This can be accomplished like so:
```bash
cd /home/user/data/Projects/example_metaGs/03_Assembly/H41_0_2_1/
awk '!/^>/ { printf "%s", $0; n = "\n" } /^>/ { print n $0; n = "" } END { printf "%s", n }' scaffolds.fasta | paste -d ";" - - | perl -F_ -ane 'if ($F[3] > 999) {print $_};' | sed -e "s/;/\n/g" > scaffolds_1000.fasta
```

Then you can run the binning module in metawrap:

```bash
conda deactivate metagenomics
conda activate metawrap
cd /home/user/data/Projects/example_metaGs/
mkdir 04_Binning
metawrap binning -o 04_Binning/H41_0_2_1 -t 20 --universal -a 03_Assembly/H41_0_2_1/scaffolds.fasta --maxbin2 --metabat2 02_qaqc/*fastq
```

### Binsanity
I'm using the scaffolds >3kb since Binsanity works best with <25,000 reads and I had too many in the 1000 bp file.

Drop scaffolds <3kb for binsanity
```bash
cd /home/user/data/Projects/example_metaGs/03_Assembly/H41_0_1_1/
awk '!/^>/ { printf "%s", $0; n = "\n" } /^>/ { print n $0; n = "" } END { printf "%s", n }' scaffolds.fasta | paste -d ";" - - | perl -F_ -ane 'if ($F[3] > 2999) {print $_};' | sed -e "s/;/\n/g" > scaffolds_3000.fasta
```

The we need to get the sequence headers from this file:
```bash
grep "^>" scaffolds_3000.fasta | sed -e 's/>//g' > scaffolds_3000_ids.txt
```

Next we need to run the differential abundance calculation for binsanity.
```bash
conda deactivate metawrap
conda activate metagenomics
cd /home/user/data/Projects/example_metaGs/04_Binning/H41_0_2_1
#the -s should point to the bam files created by metawrap.
Binsanity-profile -i ../../03_Assembly/H41_0_2_1/scaffolds_3000.fasta -s work_files/ -T 8 -o binsanity_profile --ids ../../03_Assembly/H41_0_2_1/scaffolds_3000_ids.txt -c binsanity_profile_diff_coverage
```

The we run the binsanity work flow:
```bash
Binsanity-wf -f ../../03_Assembly/H41_0_2_1/ -l scaffolds_3000.fasta -c binsanity_profile_diff_coverage.cov.x100.lognorm -o binsanity_bins --threads 10

#Rename the bins for metawrap
cd
mkdir BinSanity-Final-bins-renamed
i=0; for file in $(find ./BinSanity-Final-bins); do i=$((i+1)); cp $file BinSanity-Final-bins-renamed/"bin$i.fa"; done
```

The below steps are in extreme draft form and are really just as examples right now and may be hard to reproduce.

### Nextflow pipeline for automatic binning
Need to do this...

### Refining the bins from all 3 programs with metawrap
I really like the [metawrap bin_refinement module](https://github.com/bxlab/metaWRAP/blob/master/Module_descriptions.md#bin_refinement). You can also explore using [das_tool](https://github.com/cmks/DAS_Tool).

```bash
conda deactivate metagenomics
conda activate 
cd 04_Binning/H41_0_2_1
metawrap bin_refinement -o metawrap_bin_refinement_50_10 -t 20 -m 350 -c 50 -x 10 -A binsanity_bins/BinSanity-Final-bins-renamed/ -B maxbin2_bins/ -C metabat2_bins/
```

## Taxonomic Annotation of Bins
### GTDBTK
The metabat2 bins
```bash
conda activate gtdbtk
gtdbtk identify --genome_dir metabat2_bins/ --out_dir metabat2_bins_gtdbtk -x fa --cpus 12
gtdbtk align --identify_dir gtdbtk_id/ --out_dir gtdbtk_align --cpus 12
gtdbtk classify --genome_dir metabat2_bins --align_dir metabat2_bins_gtdbtk_id/align/ --out_dir metabat2_bins_gtdbtk_id/gtdbtk_classify -x fa --cpus 12
```
More general one-liner for the metawrap refined bins. I still need to wrap this into a short shell script that uses variable names correctly
Note that these were not the reassembled bins, that did not work very well because I lost too many of the partial genomes that are still interesting

```bash
#Oneliner for all 3 steps
gtdbtk identify --genome_dir metawrap_bins --out_dir gtdbtk_metawrap_bins -x fa --cpus 20; gtdbtk align --identify_dir gtdbtk_metawrap_bins --cpus 20 --out_dir gtdbtk_metawrap_bins/align; gtdbtk classify --genome_dir metawrap_bins --align_dir gtdbtk_metawrap_bins/align --out_dir gtdbtk_metawrap_bins/classify -x fa --cpus 20
```

### Searching for rRNA reads in the MAGs
Using barrnap which produces GFF files. Need to parse the results & add them to the massive "compare_bin_stats.ods" file I'm putting together.

```bash
#/home/user/data/Projects/Probst_MG/Miseq_MG/06_compare_binning_methods
mkdir rRNA_hybrid_gffs/
conda activate metagenomics
#These are only for the bacterial genomes (need to double check the archaeal ones)
for file in $(find hybrid_metawrap_bins/ -name "*fa"); do new_name=$(basename $file); new_name=${new_name%.*}; barrnap -k bac --reject 0.2 --threads 4 -q $file > rRNA_hybrid_gffs/$new_name.gff; done

mkdir rRNA_miseq_gffs/
for file in $(find miseq_only_metawrap_bins/ -name "*fa"); do new_name=$(basename $file); new_name=${new_name%.*}; barrnap -k bac --reject 0.2 --threads 4 -q $file > rRNA_miseq_gffs/$new_name.gff; done
```

Using python to process the barnapp GFF files
The script used is found here: 
~/data/Projects/Probst_MG/Miseq_MG/06_compare_binning_methods/parse_rRNA_gff_hits.py
This script has been updated to summarize the number of rRNA genes as well as retrieve all the sequences and save them in separate multifasta files.

We were surpsingly able to bin a lot of the rRNA genes from both sets...

## Interfacing with Anvi'o & Refinement
Seems like as good a time as any to pull everything into anvio.
```bash
cd ~/data/Projects/Probst_MG/Miseq_MG/04_assembly/spades_hybrid_02frac/
mkdir MAPPING
conda activate anvio5
cd MAPPING
bowtie2-build ../scaffolds_1000.fasta hybrid_scaffolds_1000
./bowtie_mapping_anvio.sh

cd ~/data/Projects/Probst_MG/Miseq_MG/04_assembly/spades_miseq_02frac/
mkdir MAPPING
cd MAPPING
bowtie2-build ../scaffolds_1000.fasta miseq_scaffolds_1000
./bowtie_mapping_anvio.sh
```

Generating the ANVIo contigs database for the miseq assembly:
```bash
#~/data/Projects/Probst_MG/Miseq_MG/05_binning/spades_miseq_02frac/anvio_work

anvi-gen-contigs-database -f ../../../04_assembly/spades_miseq_02frac/scaffolds_1000.fasta -o miseq_scaffolds_1000.db -n "miseq assembly scaffolds min1000 bp database for anvio"

#hmm profile
anvi-run-hmms -c miseq_scaffolds_1000.db

#Profile the BAM files
for file in $(find ~/data/Projects/Probst_MG/Miseq_MG/04_assembly/spades_miseq_02frac/MAPPING/ -name "*anvi.bam"); do outname=$(basename $file); outname=${outname%%.*}; anvi-profile -i $file -c miseq_scaffolds_1000.db -o miseq_profiles/$outname --skip-SNV-profiling --skip-hierarchical-clustering -T 4; done

#merge the profiles
anvi-merge ./*/PROFILE.db -o MERGED -c ../miseq_scaffolds_1000.db

#Import metawrap bins
cd ~/data/Projects/Probst_MG/Miseq_MG/05_binning/spades_miseq_02frac/anvio_work
sed -e "s/bin\./bin_/g" ../initial_binning/metawrap_bin_refinement_50_10/metawrap_bins.contigs > ../initial_binning/metawrap_bin_refinement_50_10/metawrap_bins_anvio.contigs

anvi-import-collection ../initial_binning/metawrap_bin_refinement_50_10/metawrap_bins_anvio.contigs -p miseq_profiles/MERGED/PROFILE.db -c miseq_scaffolds_1000.db -C "metawrap" --contigs-mode

anvi-summarize -p miseq_profiles/MERGED/PROFILE.db -c miseq_scaffolds_1000.db -o anvio_metawrap_summarize -C metawrap

```

## Functional annotation

### Complete KEGG pathway annotation
This method will give you a quick representation of the KEGG Ontology genes present within all your bins. It produces a file that works with the kegg pathways analysis module, letting you zoom into metabolic pathways that kegg has functionally outlined:
https://www.genome.jp/kegg/tool/map_pathway.html

We're using the fantastic [kofamscan](https://github.com/takaram/kofam_scan) program

