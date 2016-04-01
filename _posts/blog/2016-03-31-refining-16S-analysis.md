---
layout: post
title: Refining 16S Analysis for Deep Ocean Sediments
excerpt: "Tracking progress on finalizing deep ocean 16S sequence analysis"
---

* Table of Contents
{:toc}

## Preprossing Steps - Poorly Annotated at the moment
Done to Date:
I do not have copies of the preprocessing commands, further down I will be providing example commands.

All libraries used are from the Michigan State sequencing facility. I ended up discarding our ANL reads.

All raw reads were merged using PEAR.

Assembled reads were quality filtered at q30 using QIIME split_libraries_fastq.py.

Mothur was used to trim the sequences and remove sequences <250bp and >255bp. The primers had been removed by the sequencing facility.
{% highlight bash %}
mothur > trim.seqs(fasta = all_kostka_seqs.fna, maxhomop=7, minlength=250, maxlength = 255)
mothur > summary.seqs(fasta=all_kostka_seqs.trim.fasta)
		Start	End	NBases	Ambigs	Polymer	NumSeqs
Minimum:	1	250	250	0	3	1
2.5%-tile:	1	253	253	0	3	1837913
25%-tile:	1	253	253	0	4	18379129
Median: 	1	253	253	0	4	36758257
75%-tile:	1	253	253	0	5	55137385
97.5%-tile:	1	254	254	0	6	71678601
Maximum:	1	255	255	0	7	73516513
Mean:	1	253.071	253.071	0	4.4815
# of Seqs:	73516513

{% endhighlight %}

##Chimera Detection and Removal with usearch7
Due to the memory constraints on the free version of usearch7 I split the merged sample library back into individual sequence files
{% highlight bash %}
split_sequence_file_on_sample_ids.py -i $HOME/data/qiime_files/all_gom_seqs/all_kostka_seqs.trim.fasta -o ind_samp_seqs
{% endhighlight %}

Next, using the GA Tech biocluster environment I ran the series of commands in parallel on each individual library to remove chimeras

1) Dereplicate the files (the && waits for the command to finish with an exit status of 0 before moving to the next command)
{% highlight bash %}
usearch -derep_fulllength ${INFILE} -output ${OUTFILE} -uc ${UCFILE} -sizeout &&
{% endhighlight %}

2) Identify chimeras using the denovo detection
{% highlight bash %}
usearch -uchime_denovo ${OUTFILE} -chimeras ${CHIMFILE} &&
{% endhighlight %}
 
3) Convert the dereplicate UC file (from step 1) to a qiime mapping file
{% highlight bash %}
convert_uc2map.py ${UCFILE} > ${MAPFILE} &&
{% endhighlight %}

4) Grab all chimeric singletons
This step is needed because the OTU map file doesn't include singletons and we want to remove ALL chimeras, not just those with >1 sequences.
{% highlight bash %}
#Perl commandline, search chimera fasta file for sequences with size=1, and print out the name of that sequence ID to a new file (BADSEQIDS)
perl -ne 'if ($_ =~ m/>/ && $_ =~ m/size=1;/) { ($ID = $_) =~ s/>(.*);size.*/$1/; print $ID }' ${CHIMFILE} > ${BADSEQIDS} &&
{% endhighlight %}

5) Grab the names of all the chimeric sequences that are not singletons
This seems a bit strange to do this in 2 steps. In the end I want a list of all sequences (before dereplication) that are chimeric. So I need to be able to go back and "re-replicate" the sequences.

{% highlight bash %}
perl -ne 'if ($_ =~ m/>/ && $_ !~ m/size=1;/) {($ID = $_) =~ s/>(.*);size.*/$1/; print $ID;}' ${CHIMFILE} > ${BADOTUFILE} &&
{% endhighlight %}

6) Grab all the original sequences affiliated with a chimera (all identical sequences that were dereplicated in the first step) and add them to the chimeric singletons
{% highlight bash %}
join -j 1 <(sort -k 1 ${BADOTUFILE}) <(sort -k 1 ${MAPFILE}) | perl -pe 's/\s/\n/g' >> ${BADSEQIDS}
{% endhighlight %}

7) Using QIIME's filter_fasta to remove detected chimeras from the original fasta file
{% highlight bash %}
filter_fasta.py -f ${INFILE} -o ${NOCHIM} -s ${BADSEQIDS} -n
{% endhighlight %}

I can then concatenate all chimera-depleted fasta files into a new file called "all_kostka_seqs.trim_nochim.fasta"

The pipeline for running this on our cluster is in 2 files, a PBS script that contains the commands, and a submission script that will run this PBS on each individual sequence library. I'm working on getting a javascript implemented to collapse this section.

{% highlight bash %}
#PBS -N testing_multiple_job_submission
#PBS -l nodes=1:ppn=1
#PBS -l mem=4gb
#PBS -l walltime=6:00:00
#PBS -q iw-shared-6
#PBS -j oe
#PBS -o job_output_files/out.test_submission
#PBS -m abe
#PBS -M waoverholt@gmail.com

#dereplicate files
usearch1.7.0 -derep_fulllength ${INFILE} -output ${OUTFILE} -uc ${UCFILE} -sizeout &&

#identify chimeras
usearch1.7.0 -uchime_denovo ${OUTFILE} -chimeras ${CHIMFILE} &&

#convert uc file to a qiime map file
~/overholt_scripts/convert_uc2map.py ${UCFILE} > ${MAPFILE} &&

#grab all singletons that are not present in the OTU map file
perl -ne 'if ($_ =~ m/>/ && $_ =~ m/size=1;/) { ($ID = $_) =~ s/>(.*);size.*/$1/; print $ID }' ${CHIMFILE} > ${BADSEQIDS} &&

#identify chimeric dereps
perl -ne 'if ($_ =~ m/>/ && $_ !~ m/size=1;/) {($ID = $_) =~ s/>(.*);size.*/$1/; print $ID;}' ${CHIMFILE} > ${BADOTUFILE} &&

#grab all seqids associated with chimeric dereps & add to previously id'd chimeras
join -j 1 <(sort -k 1 ${BADOTUFILE}) <(sort -k 1 ${MAPFILE}) | perl -pe 's/\s/\n/g' >> ${BADSEQIDS}

#remove detected chimeras from original fasta file

export WORKON_HOME=$HOME/data/program_files/VirtualEnvs
source $HOME/.local/bin/virtualenvwrapper.sh
workon qiime1.9.1

filter_fasta.py -f ${INFILE} -o ${NOCHIM} -s ${BADSEQIDS} -n
{% endhighlight %}

{% highlight bash %}
#!/bin/bash
for FILE in $(find ~/data/qiime_files/all_gom_seqs/ind_samp_seqs/ -type f);
do
    BASE=${FILE%.fasta}
    qsub -v INFILE=$FILE,OUTFILE="$BASE.derep.fasta",UCFILE="$BASE.uc",CHIMFILE="$BASE.chimeras.fasta",MAPFILE="$BASE.uc.map",BADSEQIDS="$BASE.badseqids.txt",BADOTUFILE="$BASE.otu_chim.txt",NOCHIM="$BASE.nochim.fasta" job_scripts/multiple_qsub_test.pbs
{% endhighlight %}


##OTU Picking
Although I'm well aware the following is a suboptimal approach after the recent publications from the Schloss lab, I'm stuck with trying to 