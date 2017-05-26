---
layout: post
title: "Testing Megahit metagenomic assembly & binning approachs on subsampled metagenomes"
excerpt: "I'm using what I learned from the metagenomic assembly testing to do a more involved run on a subset of the data while I wait for resources on the cluster to become available to run the full dataset."
---
* Table of Contents
{:toc}

## Subsamppling the metagenomes
The first thing I need to do is subsample all the individual metagenomes. I opted to do a 1% subsetting so the following processes can run fairly quickly in a day, making the debugging and testing process that much faster.

As usual I'm using the [Enveomics](https://github.com/lmrodriguezr/enveomics) script FastA.subsample.pl to accomplish this.
I used our clusters multiple job submission format with these two scripts ([pbs script]({{site.url}}/assets/internal_files/multiple_qsub_subsample.pbs), [submission script] ({{site.url}}/assets/internal_files/submit_multiple_qsub_subsample.sh).

I then concatenate all the subsampled libraries into 1 fasta file.
{% highlight bash %}
for FILE in $(ls ind_libs); do cat $FILE >> all_1perc.fa; done
{% endhighlight %}

I re-used [my previous megahit command]({% post_url 2016-03-25-idba-assembly-testing %}/#megahit), trying to get it done in 12 hours with 40Gb of RAM. 

Building the bowtie index of the final contigs file from megahit
{% highlight bash %}
bowtie2-build ../../megahit/final.contigs.fa all_deepc_1perc
{% endhighlight %}

Mapping individual sample libraries to the index
{% highlight bash %}
bowtie2 -x all_deepc_1perc -U ../../ind_lib
s/BP101.CoupledReads.fa.1.0000-1.fa -S BP101.sam -f
{% endhighlight %}

Converting the produced SAM file to its corresponding binary BAM file
{% highlight bash %}
samtools view -bS BP101.sam > BP101.bam
{% endhighlight %}

Running in a loop
{% highlight bash %}
find ../../ind_libs/ -name "*" -type f | xargs -I file bowtie2 -x all_deepc_1perc -U file -S file.sam -f

for FILE in $(find ./ -name "*.sam" -type f); do ~/data/program_files/metageno
{% endhighlight %}

Converting the produced SAM file to its corresponding binary BAM file
{% highlight bash %}
samtools view -bS BP101.sam > BP101.bam
{% endhighlight %}

Running in a loop
{% highlight bash %}
find ../../ind_libs/ -name "*" -type f | xargs -I file bowtie2 -x all_deepc_1perc -U file -S file.sam -f

for FILE in $(find ./ -name "*.sam" -type f); do ~/data/program_files/metagenomic_binning/berkeleylab-metabat-cbdca756993e/samtools/bin/samtools view -bS $FILE > "$FILE.bam"; done

for FILE in $(find ./ -name "*.bam" -type f); do ~/data/program_files/metagenomic_binning/berkeleylab-metabat-cbdca756993e/samtools/bin/samtools sort $FILE "$FILE.sorted"
{% endhighlight %}

Run metaBAT default command
{% highlight bash %}
~/data/program_files/metagenomic_binning/berkeleylab-metabat-cbdca756993e/runMetaBat.sh ../megahit/final.contigs.fa bowtie_mapping/sam_files/*.bam
{% endhighlight %}

##Metagenomic binning on the uncontaminated oil samples
Looks like I went ahead and did a lot of work without documenting everything, shame! But running metahit on the fulldataset failed to finish so I separated the dataset into clean samples and oiled samples. Since I only care about the clean samples I pooled all of them into 1 fasta file and ran metahit on that using the above command.

From there the process is exactly as described above, except I used mutliple job submissions instead of loops to run each samples coverage.

{% highlight bash %}
#building the bowtie index from the metahit assembled contigs
bowtie2-build final.contigs.fa clean_samps

#Mapping each individual samples sequences back to this index in parallel using our clusters multiple job submission format
~/job_scripts/metagenome_seqs/submit_multiple_qsub_subsample.sh

[pbs script]({{site.url}}/assets/internal_files/multiple_qsub_bowtie.pbs)
[submission script]({{site.url}}/assets/internal_files/submit_multiple_qsub_bowtie.sh).

#Converting SAM files to BAM files with samtools
[pbs script]({{site.url}}/assets/internal_files/multiple_qsub_sam2bam.pbs)
[submission script]({{site.url}}/assets/internal_files/multiple_qsub_sam2bam.pbs)

#Running metabat with default parameters
"$HOME/data/program_files/metagenomic_binning/berkeleylab-metabat-cbdca756993e/runMetaBat.sh -t $PROCS path/megahit_full_clean/final.contigs.fa path/../bam_files/*.bam"
[pbs script]({{site.url}}/assets/internal_files/metahit.pbs)

{% endhighlight %}
