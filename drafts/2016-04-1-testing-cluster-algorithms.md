---
layout: post
title: Testing OTU clustering algorithms
excerpt: "Testing some of the OTU clustering algorithms recently mentioned by Schloss"
---

## Testing OTU clustering algorithms
I recommend checking out the following papers by [Pat Schloss](http://www.schlosslab.org/), [Westcott and Schloss, 2015](https://peerj.com/articles/1487/), [Schloss, 2016](http://www.biorxiv.org/content/early/2016/03/08/042812.abstract).

These references recommend testing OTU clustering using a Matthew's correlation coefficient (MCC) based on distances between sequences assigned to a specific OTU (label). They also conclude that average linkage clustering (mothur), abundance and distance based greedy clustering algorithms in USEARCH and VSEARCH worked the best in their datasets. 

Most of my OTU clustering experience has come from the QIIME pipelines, using primarily the UCLUST / USEARCH algorithms (USEARCH if I can get the input files small enough and uclust otherwise). I've done a little experimenting with VSEARCH, but I remember it being painfully slow and ended up switching back to the "open reference" based QIIME pipeline due to upcoming deadlines.

I'm not revisiting these topics, with more rigor, and I will try average linkage and VSEARCH on a test dataset (since I know my full dataset won't work with USEARCH). 




## Testing mothur pipeline to be able to generate the MCC values
#This has been shelved for the moment, need to get working data processed
#Dereplicate the full dataset with mothur
{% highlight bash %}
unique.seqs(fasta=all_kostka_seqs.trim.fasta)
{% endhighlight %}

This is taking too long to test efficiently, I'm subsampling the full dataset (73 million reads) to 700,000 (1%) then I'll run the OTU picking tests.

Using Enveomics script FastA.subsample.pl
{% highlight %}
mkdir test_clustering_methods
$HOME/data/program_files/enveomics/Scripts/FastA.subsample.pl all_kostka_seqs.trim.fasta -f 1 test_clustering_methods/
mv all_kostka_seqs.trim.fasta.1.0000-1.fa test_clustering_methods/test_seqs_700k.fna



## Using vsearch1.9.6
{% highlight bash %}
time ~/data/program_files/vsearch-1.9.6/bin/vsearch --derep_fulllength test_seqs_700k.fna --sizeout --output test_seqs_700k.derep.fna

#Output
Reading file test_seqs_700k.fna 100%  
186450480 nt in 736753 seqs, min 250, max 255, avg 253
Dereplicating 100%  
Sorting 100%
483327 unique sequences, avg cluster 1.5, median 1, max 3854
Writing output file 100%

real	0m10.163s
user	0m4.708s
sys	0m0.533s

time ~/data/program_files/vsearch-1.9.6/bin/vsearch --uchime_ref test_seqs_700k.derep.fna --db ~/data/program_files/Silva_ref_dbs/silva.gold.notalign.fasta --threads 1 --minh 0.2 --mindiv 1.5 --chimeras chimera.out.fasta --nonchimeras test_700k.derep.nonchim.fna

