---
layout: post
title: Large-scale OTU picking with SWARM (SUCCESS!)
excerpt: "Successfully picking OTUs using the SWARM algorithm on a large diverse set of 16S amplicons."
---

* Table of Contents

{:toc}

This post was directly taken out of this [entry]{% post_url 2016-04-27-testing_otu_picking.md %}. It successfuly used denovo OTU clustering approaches on the full sequence dataset.

I have also been successful using the [open_reference](http://qiime.org/scripts/pick_open_reference_otus.html) OTU picking pipeline with QIIME (steps1 - 3). However ~10% of the sequences always failed to cluster before time expired on the final set. See [here]({% post_url 2016-04-27-testing_otu_picking.md %}/# for more notes on this

## Testing SWARM

I'm following the recommeded pipeline proposed by Dr. [Frédéric Mahé](https://github.com/frederic-mahe/swarm/wiki/Fred's-metabarcoding-pipeline). 

This will be run on the test dataset first to get an idea on the speed and resources needed, and whether it will be feasible to run on the full dataset.

One really nice thing to note is that swarm is able to run denovo OTU clustering on multiple threads. I'm hoping this will speed up the compute time to something reasonable.

(1) First we need to dereplicate the sequences, here using vsearch
{% highlight bash %}
~/data/program_files/vsearch-1.9.6/bin/vsearch --derep_fulllength $INPUT.fasta --sizein --sizeout --fasta_width 0 --relabel "Derep_OTU" --relabel_keep --output $OUT.fasta --uc $OUT.uc
{% endhighlight %}
This took a few seconds on 1 core. It also took 15m on the full dataset, using a max of 97 Gb of RAM (wow, seems high considering I only requested 40Gb total, got lucky that there was free RAM!).

Note that I needed to request to relabel the picked OTUs in order to get the QIIME script "merge_otu_maps.txt" to function correctly (described below). I also kept the sequence seed ID to verify that the pipeline wasn't reshuffling OTUs (preventing me from mapping back to the original inflated dataset). The UC file is used to create a QIIME otu_map.

(2) I wrote a [short script]({{ site.url }}/assets/internal_files/convert_uc2map_overholt.py) that converts the UC file into the QIIME otu_map format (OTUID \t [seq1, seq2, seq3, ..., seqn]).
{% highlight bash %}
/usr/bin/time -v convert_uc2map_overholt.py $INPUT.uc > $OUT_otumap.txt
{% endhighlight %}

This took ~10 mins and used 32Gb of RAM. The script is NOT optimized and reads the full UC file into a python OrderedDict.

(3) Run swarm (v2.1.8) clustering on the dereplicated fasta seqs. The OTUs are called ">Derep_OTUXXXX" as defined by the relabel flag in vsearch.
{% highlight %}
/usr/bin/time -v swarm -d 1 -f -t 16 -z -w $OUT_seeds.fa -o $OUT_otus.txt $INPUT.fasta
{% endhighlight %}
This took 2hr31mins and used 164Gb of RAM.
It called 7million "swarms", of which the largest was 10,000.

(4) Convert the swarm otu map to a QIIME compatible otu_map. This is fairly
easy using a simple perl command to add an OTU identifier. I then run a sed
command to remove the size information so I can map the dereplicated OTUs
back to the original sequences. 
{% highlight bash %}
perl -ne -BEGIN {$count = 0}; print "denovo".$count."\t".$_; $count++;' $INPUT_swarm_otus.txt > $OUT_swarm_qiime_otumap.txt

sed -i -E 's/;size=[0-9]+;//g' $IN_swarm_qiime_otumap.txt
#The -i tells sed to run it on the file, -E is used to expand the [0-9]+ regex
{% endhighlight %}

(5) Merge the two OTU maps to make the final biom OTU table.
I do this using the QIIME script [merge_otu_maps.py](http://qiime.org/scripts/merge_otu_maps.html) followed by [make_otu_table.py](http://qiime.org/scripts/make_otu_table.html).
{% highlight bash %}
merge_otu_maps.py -i $IN_vsearch_derep_otumap.txt,$IN_swarm_qiime_otumap.txt -o merged_otu_map.txt

make_otu_table.py -i merged_otu_map.txt -o final_otutable.biom
{% endhighlight %}
Unfortunately I forgot to call the time command so I don't know specifically how many resources these two commands used.

Regardless it took 4.6 hours for this 5 step pipeline to finish using 16 procs, and 40Gb of RAM (which I seem to have overshot). 

The full pbs pipeline can be found [here]({{ site.url }}/assets/internal_files/swarm2.pbs).

FINISHED ON THE FULL DATASET IN UNDER 12 HOURS!!!!

Filtering the OTU_table to remove singletons and OTUs present in <10 samples (~1% of the total sample set).
{% highlight %]
filter_otus_from_otu_table.py -i final_otutable.biom -o final_otutable_mc2.biom -n 2 -s 10
{% endhighlight %}



{% include google_analytics.html %}

