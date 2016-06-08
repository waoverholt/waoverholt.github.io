---
layout: post
title: Refining 16S Analysis for Deep Ocean Sediments
excerpt: "Tracking progress on finalizing deep ocean 16S sequence analysis"
custom_js: collapse
modified: 2016-04-05
---
* Table of Contents
{:toc}

I've been really struggling to pick OTUs on this large database. In the past I've used the quick and dirty UCLUST method implemented in QIIME, but even these methods have been failing on this dataset. I have not allocated enough time on our cluster and they have timed out afte 10 days (and it takes a long time for these jobs to get scheduled due to the RAM and time amount requested). 

I've been meaning to do this kind of test for awhile and I would love to use the HPC-clust method 

## OTU picking with MOTHUR

{% highlight bash %}
unique.seqs(fasta=../test_600k_nochim.fasta)

#results in a fasta file with uniques, and a names file that gives all sequence headers that make up each identical sequence
#there are 380,000 unique sequences in this test group

count.seqs(name=test_600k_nochim.names)
#gives a table for the number of identical sequences in each group

#Figuring out how to trim the alignment to our region
#I aligned a subset of our sequences (1000) with the SINA online aligner
I used the following perl script to count the start & end position of each sequence. Since they all matched I could move on.
{% endhighlight %}

{% highlight perl %}

#!/usr/bin/perl 
use strict;
use warnings;

my $file = $ARGV[0];


open my $f, $file or die "Could not open file\n";

my $seq = "";
my $count = 0;
while( my $line = <$f>) {
    if ($line =~ m/>/) {
	if ($count == 0) {
	    print $line;
	    $count ++;
	}
	else {
	    #gives the fasta sequence with no returns
	    #print $seq."\n";
	    my $first = $seq;
	    $first =~ s/(-+)(A|G|C|U).*/$1/g;
	    print length($first)."\n";
	    my $reverse = reverse $seq;
	    my $last = $reverse;
	    $last =~ s/-+((A|U|G|C).*)/$1/g;
	    print length($last)."\n";
	    $seq = "";
	    print $line;
	}
    }

    else {
	chomp($line);
	$seq = $seq.$line;
    }
}
close $f;

{% endhighlight %}

{% highlight bash %}
mothur > pcr.seqs(fasta=~/data/program_files/Silva_ref_dbs/silva.gold.align, start=13861, end=23444, keepdots=F, processors=8)

mothur > system(mv ~/data/program_files/Silva_ref_dbs/silva.gold.pcr.align ~/data/program_files/Silva_ref_dbs/silva.gold.v4.align)

mothur > align.seqs(fasta=test_600k_nochim.unique.fasta, reference=~/data/progrm_files/Silva_ref_dbs/silva.gold.v4.align)
#1395 secs to align 379735 sequences
#Outputs:
#test_600k_nochim.unique.align,test_600k_nochim.unique.align.report,test_600k_nochim.unique.flip.accnos

{% endhighlight %}
{% include google_analytics.html %}