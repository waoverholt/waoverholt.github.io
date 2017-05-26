---
layout: post
title: Large-scale OTU picking with SWARM (SUCCESS!)
excerpt: "Successfully picking OTUs using the SWARM algorithm on a large diverse set of 16S amplicons."
image:
  teaser: swarm_2.0_fastidious_reduced.png
  credit: Frederic Mahe
  creditlink: https://github.com/torognes/swarm#refine_OTUs
---
* Table of Contents
{:toc}

This post was directly taken out of this [entry]({% post_url 2016-04-27-testing_otu_picking %}). It successfuly used denovo OTU clustering approaches on the full sequence dataset.

I have also been successful using the [open_reference](http://qiime.org/scripts/pick_open_reference_otus.html) OTU picking pipeline with QIIME (steps1 - 3). However ~10% of the sequences always failed to cluster before time expired on the final set. See [here]({% post_url 2016-04-27-testing_otu_picking %}#qiime-open-reference-based-pipeline) for more notes on this

## Testing SWARM

I'm following the recommeded pipeline proposed by Dr. [Frédéric Mahé](https://github.com/frederic-mahe/swarm/wiki/Fred's-metabarcoding-pipeline). 

This will be run on the test dataset first to get an idea on the speed and resources needed, and whether it will be feasible to run on the full dataset.

One really nice thing to note is that swarm is able to run denovo OTU clustering on multiple threads. I'm hoping this will speed up the compute time to something reasonable.

###Step 1
First we need to dereplicate the sequences, here using vsearch
{% highlight bash %}
~/data/program_files/vsearch-1.9.6/bin/vsearch --derep_fulllength $INPUT.fasta --sizein --sizeout --fasta_width 0 --relabel "Derep_OTU" --relabel_keep --output $OUT.fasta --uc $OUT.uc
{% endhighlight %}
This took a few seconds on 1 core. It also took 15m on the full dataset, using a max of 97 Gb of RAM (wow, seems high considering I only requested 40Gb total, got lucky that there was free RAM!).

Note that I needed to request to relabel the picked OTUs in order to get the QIIME script "merge_otu_maps.txt" to function correctly (described below). I also kept the sequence seed ID to verify that the pipeline wasn't reshuffling OTUs (preventing me from mapping back to the original inflated dataset). The UC file is used to create a QIIME otu_map.

###Step 2
I wrote a [short script]({{ site.url }}/assets/internal_files/convert_uc2map_overholt.py) that converts the UC file into the QIIME otu_map format (OTUID \t [seq1, seq2, seq3, ..., seqn]).
{% highlight bash %}
/usr/bin/time -v convert_uc2map_overholt.py $INPUT.uc > $OUT_otumap.txt
{% endhighlight %}

This took ~10 mins and used 32Gb of RAM. The script is NOT optimized and reads the full UC file into a python OrderedDict.

###Step 3
Run swarm (v2.1.8) clustering on the dereplicated fasta seqs. The OTUs are called ">Derep_OTUXXXX" as defined by the relabel flag in vsearch.
{% highlight bash %}
/usr/bin/time -v swarm -d 1 -f -t 16 -z -w $OUT_seeds.fa -o $OUT_otus.txt $INPUT.fasta
{% endhighlight %}
This took 2hr31mins and used 164Gb of RAM.
It called 7million "swarms", of which the largest was 10,000.

###Step 4
Convert the swarm otu map to a QIIME compatible otu_map. This is fairly
easy using a simple perl command to add an OTU identifier. I then run a sed
command to remove the size information so I can map the dereplicated OTUs
back to the original sequences. 
{% highlight bash %}
perl -ne -BEGIN {$count = 0}; print "denovo".$count."\t".$_; $count++;' $INPUT_swarm_otus.txt > $OUT_swarm_qiime_otumap.txt

sed -i -E 's/;size=[0-9]+;//g' $IN_swarm_qiime_otumap.txt
#The -i tells sed to run it on the file, -E is used to expand the [0-9]+ regex
{% endhighlight %}

###Step 5
Merge the two OTU maps to make the final biom OTU table.
I do this using the QIIME script [merge_otu_maps.py](http://qiime.org/scripts/merge_otu_maps.html) followed by [make_otu_table.py](http://qiime.org/scripts/make_otu_table.html).
{% highlight bash %}
merge_otu_maps.py -i $IN_vsearch_derep_otumap.txt,$IN_swarm_qiime_otumap.txt -o merged_otu_map.txt

make_otu_table.py -i merged_otu_map.txt -o final_otutable.biom
{% endhighlight %}
Unfortunately I forgot to call the time command so I don't know specifically how many resources these two commands used.

Regardless it took 4.6 hours for this 5 step pipeline to finish using 16 procs, and 40Gb of RAM (which I seem to have overshot). 

The full pbs pipeline can be found [here]({{ site.url }}/assets/internal_files/swarm2.pbs).

FINISHED ON THE FULL DATASET IN UNDER 12 HOURS!!!!

## Filtering OTU Table
Filtering the OTU_table to remove singletons and OTUs present in <10 samples (~1% of the total sample set).
{% highlight bash %}
filter_otus_from_otu_table.py -i final_otutable.biom -o final_otutable_mc2.biom -n 2 -s 50
{% endhighlight %}
This produced ~300,000 OTUS (4%) using 47 million reads (75%) of the total starting library.

Convert the OTU names in the swarm_seeds.fa file to the denovo OTU names in the biom file.
{% highlight bash %}
perl -ne 'BEGIN {$count = 0}; if ($_ =~ m/>/) {print ">denovo".$count."\t".$_; $count++;} else {print $_}' swarm_seeds.fa > swarm_seeds_rename.fa

sed -E 's/\t.*//g' swarm_seeds_rename.fa > swarm_seeds_rename_nosize.fa
{% endhighlight %}

{% highlight bash %}
filter_fasta.py -f swarm_seeds_rename_nosize.fa -b final_otutable_mc2_s50.biom -o rep_set_mc2_s50.fa
{% endhighlight %}

## Assigning taxonomy
I'm interested in using both the SILVA (123) and GreenGenes (13_8) databases for classification with RDP. I want to see if the dominant OTUs give consistent taxonomies (unlikely I think). 

{% highlight bash %}
assign_taxonomy.py -i rep_set_mc2_s50.fa -o assign_taxa_silva123_all_97_majority -r /nv/hp10/woverholt3/data/databases/Silva_123_provisional_release_QIIME/SILVA123_QIIME_release/rep_set/rep_set_all/97/97_otus.fasta -t /nv/hp10/woverholt3/data/databases/Silva_123_provisional_release_QIIME/SILVA123_QIIME_release/taxonomy/taxonomy_all/97/majority_taxonomy_7_levels.txt -m rdp -c 0.5 --rdp_max_memory 20000

assign_taxonomy.py -i rep_set_mc2_s50.fa -o assign_taxa_silva123_16S_97_majority -r /nv/hp10/woverholt3/data/databases/Silva_123_provisional_release_QIIME/SILVA123_QIIME_release/rep_set/rep_set_16S_only/97/97_otus_16S.fasta -t /nv/hp10/woverholt3/data/databases/Silva_123_provisional_release_QIIME/SILVA123_QIIME_release/taxonomy/16S_only/97/majority_taxonomy_7_levels.txt -m rdp -c 0.5

assign_taxonomy.py -i rep_set_mc2_s50.fa -o assign_taxa_gg_13_8_97 -r $HOME/data/program_files/qiime1.8/gg_otus-13_8-release/rep_set/97_otus.fasta -t $HOME/data/program_files/qiime1.8/gg_otus-13_8-release/taxonomy/97_otu_taxonomy.txt -m rdp -c 0.5

biom add-metadata -i final_otutable_mc2_s50.biom -o final_otutable_mc2_s50
_sivla_all_tax.biom --observation-metadata-fp assign_taxa_silva123_all_97_majority/rep_set_mc2_s50_tax_assignments.txt --observation-header OTUID,taxonomy,confidence --sc-separated taxonomy

{% endhighlight %}
I want to test the different taxonomies to see if I can make an easy decision based on annotation of the most abundant OTU (which I'm most concerned with since these will drive the beta distances I'll use). 

Here is a quick perl oneliner to convert the merged_otu_map.txt to a 2 column file with OTUID and #seqs (observations). Then I'll sort the output using the linux "sort" function.
{% highlight bash %}
perl -a -ne 'print $F[0]."\t".scalar(@F)."\n"' merged_otumap.txt > list_seqs_per_otu.txt
sort -k2rn list_seqs_per_otu.txt -o list_seqs_per_otu.txt
#-k2rn tells sort to use the 2nd column, sort (n)umerically and descending(r). -o will sort "in-place". Don't try to use shell redirects to sort in place i.e. "sort file > file".
{% endhighlight %}

For the most part the OTUs were close to sorted based on how swarm works (using the most abundant dereplicated reads as seeds to start). However, there were a few re-arrangments (OTU 0, 1, 14, 13, 2, 3, 21, ...).

I have already excluded RDP's training set since it only has one Thaumarchaeota. I know this group is VERY abundant and with RDP all OTU will be classified with 100% confidence to Nitrosopumilus. I blasted a couple OTUs and the seqID to this genus ranges from 89-92%.

The Silva_All reference dataset had 1 OTU match the domain Eukaryota (and no further levels). This OTU had 146 sequences. In Silva_16S and GG_13_8 it hit Mitochondria. I'll only use Silva_16S for the remainder of the analysis.

{% include table_format.html %}

|OTUID| GreenGenes | Silva16S |
|----|----|----|
|0|k__Bacteria;p__Proteobacteria;c__Deltaproteobacteria|D_0__Bacteria;D_1__Proteobacteria;D_2__Deltaproteobacteria;D_3__Syntrophobacterales;D_4__Syntrophobacteraceae;D_5__uncultured;Ambiguous_taxa|
|1|k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Thiotrichales;f__Piscirickettsiaceae;g__;s__|D_0__Bacteria;D_1__Proteobacteria;D_2__Gammaproteobacteria;D_3__Xanthomonadales;D_4__JTB255 marine benthic group;D_5__uncultured deep-sea bacterium;D_6__uncultured deep-sea bacterium|
|14|k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Thiotrichales;f__Piscirickettsiaceae;g__;s__|D_0__Bacteria;D_1__Proteobacteria;D_2__Gammaproteobacteria;D_3__Xanthomonadales;D_4__JTB255 marine benthic group;D_5__uncultured sediment bacterium;D_6__uncultured sediment bacterium|
|13|k__Bacteria;p__Chloroflexi;c__Anaerolineae;o__GCA004;f__;g__;s__|D_0__Bacteria;D_1__Chloroflexi;D_2__Anaerolineae;D_3__Anaerolineales;D_4__Anaerolineaceae;D_5__uncultured|
|2|k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Thiotrichales;f__Piscirickettsiaceae;g__;s__|D_0__Bacteria;D_1__Proteobacteria;D_2__Gammaproteobacteria;D_3__Xanthomonadales;D_4__uncultured;Ambiguous_taxa;Ambiguous_taxa|
|3|k__Archaea;p__Crenarchaeota;c__Thaumarchaeota;o__Cenarchaeales;f__Cenarchaeaceae;g__;s__|D_0__Archaea;D_1__Thaumarchaeota;D_2__Marine Group I;Ambiguous_taxa;Ambiguous_taxa;Ambiguous_taxa;D_6__uncultured archaeon|
|15|k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Thiotrichales;f__Piscirickettsiaceae;g__;s__|D_0__Bacteria;D_1__Proteobacteria;D_2__Gammaproteobacteria;D_3__Xanthomonadales;D_4__JTB255 marine benthic group|

I ran this for several more, but with just these 7 I can decide to use Silva. It simply allows me to better compare to other deep ocean sediment studies which have primarily been conducted by German groups / German trained groups that use Silva.
For example for OTU1, I'd rather have the sequence annotated as JTB255 Marine Benthic Group (Xanthos) than Piscirickettsiaceae. I'd also rather use Marine Group I Thaums over Cenarchaeaceae (of which the type strain is a shallow-water sponge symbiont). 

## Checking Mason seqs
I have a q30 filtered file named qc_seqs.fna. I do not remember if this is only Mason seqs or is already merged with an older version of my seq database.

I screen for anything not labeled with a Mason seqID using awk & grep
{% highlight bash %}
awk 'NR % 2' qc_seqs.fasta | grep -E -v 'SD|SU|SE'
{% endhighlight %}

Pick OTUs against my SWARM reference OTUs.
{% highlight bash %}
INPUT=$HOME/data/qiime_files/all-hi-qual_deepc/mason_16S/qc_seqs.fasta
OUTPUT=$HOME/data/qiime_files/all_gom_seqs/swarm_full_dataset/mason_swarmref_uclust
REF=$HOME/data/qiime_files/all_gom_seqs/swarm_full_dataset/rep_set_mc2_s50.fa

parallel_pick_otus_uclust_ref.py -i $INPUT -o $OUTPUT -z -O 20 -r $REF
{% endhighlight %}
Approximately 5 million sequences (out of 25 million QA/QC seqs) from the Mason dataset failed to cluster with my representative sequences. I was hoping for closer to the 80-90% mark, but I'm happy with 75%. We shall see if reviewers have similar thoughts. This will falsely increase the similarity between my datasets and the Mason datasets. I'm suspecting (maybe a bit naively) that may be due to similarities between my reference sequences and her < EPA samples, and large differences to the > EPA limit samples (which I don't have any good references for in my sequence set).


Align references sequences against the [MOTHUR provided SEED database](http://www.mothur.org/wiki/Silva_reference_files). I had previously trimmed the 50,000 column Silva alignment to the v4 region {% post_url 2016-04-27-testing_otu_picking %}.

There is a weird bug in v1.36.1 where you can't have "seed" in the file of the reference dataset. So I changed the file to silva.seeed_v123.align)
{% highlight bash %}
~/data/program_files/mothur/mothur
mothur > align.seqs(fasta=test.fa, reference=silva.seeed_v123.align)

sed -i -E 's/\./-/g' test.fa

pcr.seqs(fasta=silva.seeed_v123.align, start=13861, end=23444, keepdots=F, processors=6)

{% endhighlight %}

I did a stupid.
rm test(autotab completion gave 1 file when I was expecting many) *
deleted all non-folder files...

Thankfully I had transferred all final step tables and the repset fasta file to my personal comp. I'll see if any of those intermediate files are critically important (I think not, but I may need to start again). Note, if I have to go back to grab info from one of the lost files, I will re-run everything. There is a good chance I'll get slightly different OTUs and I won't want to blend those.

{% highlight bash %}
align.seqs(fasta=rep_set.fa, reference=silva_seeed_v123.v4.align)
filter.seqs(fasta=rep_set.align)
{% endhighlight %}

I used phyloseq's implementation of "fast unifrac" instead. It gave consistent results with vegan's "bray curtis" dissimilarities. Although, BC still gave better clustering visualization for ease of understanding the broad patterns.

I made the phylogenetic tree by aligning sequences to the SILVA alignment and then using fasttree to make a pseudo-ML tree.

Visualizing this tree showed 1 large clade with VERY long branches. I spot checked 1 of the OTU sequences from this long branch and it did not hit any reference 16S rRNA gene in BLAST, and online RDP classifier failed to classify it more than Bacteria.

I grabbed all the sequence identifiers in this clade using dendroscope (2130 sequences in total).

I used QIIME's "filter_otus_from_otu_table.py" to keep only these long sequences so I could see how abundant they were.

{% highlight bash %}
filter_otus_from_otu_table.py
 -i final_otutable_mc2_s50.biom -o final_otutable_mc2_s50_ONLY-LONG-BRANCHES.biom -e long_branches_in_fasttree_mc2_s50.txt --negate_ids_to_exclude
{% endhighlight %}

These 2130 OTU represented 5.3 million total counts (just over 10% of the total sequence library).

{% highlight bash %}
filter_fasta.py -f rep_set.fna -s long_branches_in_tree.txt -o only_long_branches.fasta
{% endhighlight %}

Those long branches are all Archaea...

				    
{% include google_analytics.html %}

