---
layout: post
title: RaXML-EPA and iTOL
excerpt: "Inserting and visualizing short read sequences into a curated phylogenetic tree using RaXML-EPA and the interactive tree of life."
---
* Table of Contents
{:toc}

## The plan
1. Identify the backbone sequences needed to generate the phylogenetic tree.
 - use BLAST or insert in ARB SILVA database
2. Use RaXML to generate the bootstrapped ML tree from the reference sequences.
3. Use papara or SILVA to align the Illumina sequences to the reference tree.
4. Insert the aligned OTU into the reference tree using RaXML-EPA.
5. Convert the .jplace into a datasheet format that iToL can read.
 - Enveomics script by L.M.M. Rodriguez-R
 - Custom script
6. ???
7. Profit


## Constructing the Reference Tree
**The set-up.**
I'm working with a dataset that includes ~800,000 16S amplicon illumina sequences and ~400 mid-full length 16S clone sequences. The environment these come from is poorly characterized and most of the sequences don't have close isolates. The goal is to describe some of the dominant populations and it was decided that longer sequences were needed to improve the confidence in phylogenetic placements.

**The first iteration**
*Note: I didn't save all the commands for this...*
The first reference tree was made by BLASTing the clone sequences against refseq_rna and grabbing the closest named isolate (if possible) or closest uncharacterized high quality sequence.

This collection of sequences was aligned with clustal-omega. Representative OTU illumina sequences (~40,000) were aligned using papara (I don't think this was ideal), inserted using RaXML-EPA, and the resultant .jplace file was modified using the [JPlace.to_iToL.rb](https://github.com/lmrodriguezr/enveomics/blob/master/Scripts/JPlace.to_iToL.rb) script in [enveomics](http://enve-omics.ce.gatech.edu/enveomics/).

**The second iteration**
*This will be documented*
This tree was built by aliging the clone sequences using SILVA and they were inserted into a pre-made ARB tree (SILVA v.128 Ref_NR_99). Close relatives were manually chosen and I included a broader range of outgroups.

Aligned sequences were exported in FASTA format. There might be an issue with names that I need to fix manually (yes there was)...

## Aligning the illumina OTU sequences
I'm using the [mothur recreated SEED database](https://www.mothur.org/w/images/a/a4/Silva.seed_v128.tgz) to align the illumina OTU sequences.

{% highlight bash %}
parallel_align_seqs_pynast.py -i rep_set_filtered.good.filter.trim.fasta -o pynast_silva_align -t ~/program_files/Silva/silva.seed_v128.align -O 4
{% endhighlight %}

I then merge the two alignment files, use the [lane-mask](https://www.mothur.org/wiki/Lane_mask) provided by [Dr. Schloss](http://www.schlosslab.org/) to filter the alignment, then pull out the reference sequences again. 

{% highlight bash %}
filter_alignment.py -i arbref_and_otu_aligned.fna -o filter_align -m ~/program_files/Silva/Silva_123_provisional_release/SILVA123_QIIME_release/Lane1349.silva.filter.txt
{% endhighlight %}


## Constructing the ML bootstrapped tree
I'm not sure what the most appropriate way to make the reference tree is. It is temping to use the ARB NJ tree since the topology is so well grounded by the 600,000 curated sequences.

However, I am also making a RaXML tree and I'll double check the topologies match.

{% highlight bash %}

{% endhighlight %}

*Note: The first time I used raxml's default masking and the tree topology was not good. I've since gone back to apply the lane-mask to try and improve the raxml tree. If this doesn't work I'll export the ARB NJ tree and use it!

*Note2: Tree is still not correct, and I ended up using the exported ARB tree.

## Inserting the Illumina Sequences
Luckly I have everything I need to do this:
(1) A tree
(2) full set of sequences to insert including ref seqs already in the tree

{% highlight bash %}
#RAXML Tree
raxmlHPC-PTHREADS -f v -T 5 -s refseqs_an
d_otu_aligned.fna -t RAxML_bipartitionsBranchLabels.REFTREE -m GTRGAMMA -n EPA
#arb tree
raxmlHPC-PTHREADS -f v -T 5 -s arbref_and_otu_aligned_pfiltered.fasta -t ../raxml/overholt2_small.tree -m GTRGAMMA -n EPA
{% endhighlight %}

## Creating the dataset showing where illumina sequences placed
I'm currently using two scripts to convert the jplace file to a format that iToL can recognize.

The first script is written by [Luis M. Rodriguez-R](http://lmrodriguezr.github.io/) in the [enveomics](https://peerj.com/preprints/1900/) collection. I use this script solely to grab the tree that Miguel reformats from the jplace file to play nicely with iToL. If you did your RaXML-EPA mapping in a different way (each sequence library separately) you would be able to only use this script.

{% highlight bash %}
~/program_files/enveomics/Scripts/JPlace.to_iToL.rb -i RAxML_portableTree.EPA.jplace -o itol -u test
{% endhighlight bash %}

I, however, mapped OTU representative sequences onto the tree and inorder to correctly displace the true abundances I needed to inflate these back into the reads assigned to that OTU.

I wrote a quick python script that follows the logic of Miguel's ruby script (namely I grab the most likely node placement for each OTU), and generate a list of all the OTU that were placed at the same node. I can then use the OTU table (tab-delimited format) to sum all sequences from each library placed at each node in the tree.

I've currently set the default radius size to be the sum of the total reads assigned, but that can be changed easily after the script is run (its the 3rd column). The default piechart location is in the middle of the branch (2nd column). If you change the value from 0.5 to -1, the external piecharts will be plotted at the leaves. Values from 0 (start of node branch) to 1 (end of node branch) can also be used.

The colors for each sample need to be assigned separately and added to this dataset. I recommend using these two websites [1](http://tools.medialab.sciences-po.fr/iwanthue/examples.php) [2](http://phrogz.net/css/distinct-colors.html) to get discrete colors. Lots of other options for generating gradients.

[my script]({{site.url}}/assets/internal_files/jplace_otuids.py)
{% highlight bash %}
~/Projects/scripts/jplace_otuids.py -i RAxML_portableTree.EPA.jplace -o test_output.txt -c ../avg_norm_otutable.txt
{% endhighlight %}

## Using iToL
From here it is pretty straightforward to upload your tree and your datafile into a project and then play with all the options.

{% include google_analytics.html %}

