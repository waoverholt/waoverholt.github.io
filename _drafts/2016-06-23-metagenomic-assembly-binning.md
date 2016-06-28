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

I re-used [my previous megahit command]({% post.url 2016-03-25-idba-assembly-testing.md %}/#megahit), trying to get it done in 12 hours with 40Gb of RAM. 
