---
layout: post
title: Testing different OTU clustering approaches - work in progress
excerpt: "Figuring out how to cluster a very large number of sequences, this is a long-term work in progress"
---

* Table of Contents

{:toc}

## Trying to use HPC tools
This has been a project I've picked up several times over the last year. It sounds too good to be true, and in the note - I've never got it to work satisfactorily. The idea is to use the widely regarded average-linkage hierarchical clustering approach to pick OTUs. I've had the opinion that the fastest "greedy" clustering approaches that I've mostly used (uclust) do not do a great job. While I haven't gone to great strides to prove it, uclust often seems to make many OTUs that should all be clustered together, and on the otherside put sequences together that shouldn't be. 

I recently read several of [Pat Schoss's](http://www.schlosslab.org/) latest papers concluding that average-linkage (as used in Mothur) typically work the ["best"](http://www.schlosslab.org/assets/pdf/2015_westcott.pdf) under his test conditions. However, even after dereplication, my largest project libraries have >20 million high quality, [chimera filtered]({% post_url 2016-03-31-refining-16S-analysis %}) sequences.

Here I'm using the [infernal aligner](http://eddylab.org/infernal/) since it has mpi support for rapid alignment of millions of sequences.

{% highlight bash %}
#~ 600,000 sequences
mpirun -np 80 -hostfile $PBS_NODEFILE (list of nodes) cmalign --mpi -o $OUTPUT --outformat Pfam --matchonly --mxsize 5000 --noprob /nv/hp10/woverholt3/data/program_files/infernal-1.1.1/bacteria_0p1.cm $INPUT

# CPU time: 7373.08u 12.55s 02:03:05.63 Elapsed: 02:21:03.35

#real	141m44.270s
#user	1092m36.027s
#sys	0m45.431s


{% endhighlight %}
[PBS Script Used]({{ site.url }}/assets/internal_files/infernal_mpi.txt)

Next I use the program [hpc-clust](http://meringlab.org/software/hpc-clust/) with average linkage settings to cluster the aligned sequences.

{% highlight bash %}

mpirun -np 40 -hostfile "list of hosts" hpc-clust-mpi -al true $INPUT

#real	9m6.698s
#user	32m23.941s
#sys	1m9.842s

#required 260Gb of Ram across the 40 procs.
#WOW
{% endhighlight %}
[PBS Script Used]({{ site.url }}/assets/internal_files/hpc-clust-mpi.txt)

The hpc-clust program comes with a shell script to convert the results to an OTU table at the distance specified (using 0.97 here).

The average linkage results in 600,000+ OTUs clustered at 0.97. This seems ridiculous and I'm working on getting to the bottom of it. My working assumption is the infernal alignment is not very good, and I'm going to switch to testing mothur's alignment method and clustering, and compare that to this method and mothur's aligment with HPC-clust on a much smaller test database. 


## Mothur
mothur > unique.seqs(fasta=../test_600k_nochim.fasta)
#results in a fasta file with uniques, and a names file that gives all sequence headers that make up each identical sequence
#there are 380,000 unique sequences in this test group

count.seqs(name=test_600k_nochim.names)
#gives a table for the number of identical sequences in each group

#Figuring out how to trim the alignment to our region
#I aligned a subset of our sequences (1000) with the SINA online aligner
I used the following perl script to count the start & end position of each sequence. Note, I used perl here since I spent an hour trying to get this to work in the commandline (perl -ne) and ulimately got lost in the jargon. Since they all matched I could move on.
{% endhighlight %}

{% highlight perl %}

#!/usr/bin/perl 
use strict;
use warnings;

#read the file from the commandline
my $file = $ARGV[0];


open my $f, $file or die "Could not open file\n";


my $seq = "";
my $count = 0;
while( my $line = <$f>) {
    if ($line =~ m/>/) {
       #account for the first line being different
	if ($count == 0) {
	    print $line;
	    $count ++;
	}
	else {
	    #gives the fasta sequence with no returns
	    #print $seq."\n";
	    my $first = $seq;
	    #count the number of gaps until the first base
	    $first =~ s/(-+)(A|G|C|U).*/$1/g;
	    print length($first)."\n";
	    #reverse the sequence and count from the other direction
	    my $reverse = reverse $seq;
	    my $last = $reverse;
	    #this subsets the sequence by removing all the gaps from the back end of the sequence & counting the remainder
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
#trim the v123 silva alignment file from Mothur to the region covered by our sequences
mothur > pcr.seqs(fasta=~/data/program_files/Silva_ref_dbs/silva.nr_v123.align, start=13861, end=23444, keepdots=F, processors=8)

mothur > system(mv ~/data/program_files/Silva_ref_dbs/silva.nr_v123.pcr.align ~/data/program_files/Silva_ref_dbs/silva.nr_v123.v4.align)

#align our test sequences with the trimmed alignment
mothur > align.seqs(fasta=test_600k_nochim.unique.fasta, reference=~/data/progrm_files/Silva_ref_dbs/silva.nr_v123.v4.align)
#12479 seconds to align 379735 sequences
#output files: test_600k_nochim.unique.align, test_600k_nochim.unique.align.report, test_600k_nochim.unique.flip.accnos

mothur > dist.seqs(fasta=test_600k_nochim.unique.align, cutoff=0.20, processors=8)

{% endhighlight %}

## HPC-clust with Mothur Alignment
Running HPC-clust on the mothur aligned sequences to compare results
Note that HPC-clust expects U instead of T, need to change all instances in the mothur sequences

{% highlight bash %}
perl -ne 'if ($_ =~ m/>/) {print $_;} else {($seq = $_) =~ s/T/U/g; print $seq}' test_600k_nochim.unique.align > test_600k_nochim.unique.U.align
{% endhighlight bash %}

Turns out there were some dots left in the alignment (~3000 of the sequences) even after giving the keepdots=F flag? I used perl to change these to dashes. Fair?
{% highlight bash %}
perl -ne 'if ($_ =~ m/>/) {print $_;} else {($seq = $_) =~ s/\./-/g; print $seq}' test_600k_nochim.unique.U.align > test_600k_nochim.unique.Udot.align
{% endhighlight bash %}


The I can run HPC-clust through our cluster environment.
{% highlight bash %}
#PBS -N mpi-hpc-clust-align
#PBS -l nodes=5:ppn=4
#PBS -l mem=50gb
#PBS -l walltime=01:00:00:00
#PBS -q biocluster-6
#PBS -j oe
#PBS -o $HOME/job_output_files/hpc-clust-deepc.$PBS_JOBID
#PBS -m abe
#PBS -M waoverholt@gmail.com

module unload gcc/4.7.2
module load intel/14.0.2 openmpi/1.6

INPUT=$HOME/data/qiime_files/all_gom_seqs/test_fastas/mothur/test_600k_nochim.unique.Udot.align
PROCS=`wc -l < ${PBS_NODEFILE}`

echo "started on `/bin/hostname`"
echo
echo "PATH is [$PATH]"
echo
echo "Nodes chosen are:"
cat $PBS_NODEFILE
echo

COMMAND="mpirun -np $PROCS -hostfile $PBS_NODEFILE /usr/local/packages/hpc-clust/1.1.1/openmpi-1.6.2/intel-14.0.2/bin/hpc-clust-mpi -al true $INPUT"

time $COMMAND

echo $COMMAND
{% endhighlight %}

This command has failed twice now. It ran out of memory when I requested 150 Gb. I just resubmitted with 300 Gb requested for 36 hours. I dropped the nodes down to 20 instead of 40 to hopefully get faster access to nodes. This clustering algorithm seems to be memory limited and not CPU limited (as expected with a hierarchal approach). 

Failed again, canceled after using 317Gb of memory.

Time to drop it to 10%, 20%, and 50% and see if we can predict the neccessary amount. Although I'm thinking this route is not feasible. 

Running with mpi & using 16 procs.

10% = 38,059 sequences = 24 minutes = 23Gb RAM = 1 OTU
20% = 75,824 sequences = 

Guess I should have tried the smaller dataset ages ago. Only 1 OTU???

## QIIME open reference based pipeline
This is the pipeline that was written to handle very large sequence databases and has all sorts of issues with it. However, it is fast, scales reasonably well, and probably doesn't distort the ecological picture on a very high level. This may well be what I'm forced to do if I can't figure out a robust method that will complete with the resourses I have available. I will say that even this pipeline fails on the full dataset on step4 (recovering all sequences that failed to cluster against greengenes and the 1% subsampling I used in step2). I have about 16million sequences that failed to be assigned in steps1-3.

This command was run through the cluster pbs script qiime_open_ref_otus.pbs The qiime command is reproduced below.

{% highlight bash %}
pick_open_reference_otus.py -i $HOME/data/qiime_files/all_gom_seqs/test_fastas/test_600k_nochim.fasta -o $HOME/data/qiime_files/all_gom_seqs/test_fastas/qiime_open_ref/ -p $HOME/data/program_files/qiime1.8/qiime_params -0 8 --suppress_align_and_tree

#the params file had enable_rev_strand_match True

{% endhighlight %}

In the end this method identified 121,171 OTUs (27,438 OTUs after removing singletons). This took ~20 minutes of CPU time (running on 8 nodes, with 50gbs avaiable). All told it took 31 Gbs of RAM (likely double what I needed since these sequences should all be in the same direction).

I am not doing anything nearly as clever as Dr. Pat Schloss about checking the quality and reproducibility of the methods being tested. This is more about scaling, feasibility, and a "gut check" for number of OTU detected. 

## QIIME denovo clustering with uclust (default)
I know there are plenty of problems with the greedy clustering algorithm "uclust" and that Dr. Robert Edgar has updated this several times. I have used it many times in the past and I wanted to include this as a baseline connection to other work I've done.

I ran this through the pbs script qiime_denovo_uclust.pbs (the qiime command is posted below).

{% highlight bash %}
pick_otus.py -i $HOME/data/qiime_files/all_gom_seqs/test_fastas/test_600k_nochim.fasta -o $HOME/data/qiime_files/all_gom_seqs/test_fastas/qiime_denovo_uclust -m uclust -z
{% endhighlight %}

Here I identified 122,772 OTUs (27,630 OTUs after removing singletons). It took 13 minutes on 1 proc, using 1.2 Gbs of RAM. 


Running this on the full dataset with 10% subsampling failed after 1 week of compute time on the cluster with distributing the parallelized commands to 100 cores. It failed on step3, using denovo identified OTUs from the 10% subsampling as a reference. I restarted this grabbing the last command for the qiime log file.

{% highlight bash %}
parallel_pick_otus_uclust_ref.py -i /nv/hp10/woverholt3/data/qiime_files/all_gom_seqs/qiime_open_ref_20160502/step1_otus/failures.fasta -o /nv/hp10/woverholt3/data/qiime_files/all_gom_seqs/qiime_open_ref_20160502/step3_otus/ -r /nv/hp10/woverholt3/data/qiime_files/all_gom_seqs/qiime_open_ref_20160502/step2_otus//step2_rep_set.fna -T --jobs_to_start 100 --enable_rev_strand_match --similarity 0.97
{% endhighlight %}

I can use old log files to manually finish the pipeline if this works.

######

## Using QIIME to prescreen sequences
Since it seems there may be sequences that are really bugging down the OTU picking process I've decided to see if screening all the sequences against greengenes at a low percent ID (70) helps sort out the issue. The idea is that any sequence that is <70% similar to any sequence in greengenes is divergent enough to really slow down the process (and is likely junk, although I'll screen that later). 

{% highlight bash %}
INPUT=$HOME/data/qiime_files/all_gom_seqs/test_fastas/test_600k_nochim.fasta
OUTPUT=$HOME/data/qiime_files/all_gom_seqs/test_fastas/qiime_uclust_ref_screen

parallel_pick_otus_uclust_ref.py -i $INPUT -o $OUTPUT -z -O 50 -r $GG_otus -s 0.70
{% endhighlight %}

On the test dataset I got 532 sequences that failed. I really doubt this is the issue.
Of these ~169 were phiX. Still working on the other 350, but not that important in the big scheme of things (I think). 


{% include google_analytics.html %}