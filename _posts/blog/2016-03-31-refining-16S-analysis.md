---
layout: post
title: Refining 16S Analysis for Deep Ocean Sediments
excerpt: "Tracking progress on finalizing deep ocean 16S sequence analysis"
custom_js: collapse
modified: 2016-04-05
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

2) Identify chimeras using the denovo detection and export the nonchimeras
{% highlight bash %}
usearch -uchime_denovo ${OUTFILE} -nonchimeras ${NONCHIMFILE} &&
{% endhighlight %}
 
3) From those remaining sequences ID reference based chimeras agains't silva's gold database
{% highlight bash %}
usearch1.7.0 -uchime_ref ${NONCHIMFILE} -db /nv/hp10/woverholt3/data/program_files/Silva_ref_dbs/silva.gold.notalign.fasta -nonchimeras ${NONCHIMNONREF} -strand plus &&
{% endhighlight %}

4) Convert the dereplicate UC file (from step 1) to a qiime mapping file
I need this to go back and "rereplicate" the sequences before OTU picking
{% highlight bash %}
convert_uc2map.py ${UCFILE} > ${MAPFILE} &&
{% endhighlight %}

5) Identify dereplicated sequence headers representing nonchimeras (each representing a cluster of identical sequences). I grab only those greater than size 1, since the qiime mapping file does not have single tons present (these are handled next).
{% highlight bash %}
perl -ne 'if ($_ =~ m/>/ && $_ !~ m/size=1;/) {($ID = $_) =~ s/>(.*);size.*/$1/; print $ID;}' ${NONCHIMNONREF} > ${GOODOTUFILE} &&
{% endhighlight %}

6) Identify all the nonchimeric singletons (missing from the otu mapping file)
{% highlight bash %}
perl -ne 'if ($_ =~ m/>/ && $_ =~ m/size=1;/) { ($ID = $_) =~ s/>(.*);size.*/$1/; print $ID }' ${NONCHIMNONREF} > ${GOODSEQIDS} &&
{% endhighlight %}

7) Merge the two sequence ID lists together as input for qiime's filter_fasta
Note the double escapes in the perl command, I didn't quite figure why this was necessary, but it took me WAAY too long to get it to work. 
{% highlight bash %}
join -j 1 <(sort -k 1 ${GOODOTUFILE}) <(sort -k 1 ${MAPFILE}) | perl -pe "s/\\s/\\n/g" >> ${GOODSEQIDS} &&
{% endhighlight %}

8) Use QIIME to get all the nonchimeric sequences from the original fasta file using the ID'd "good" reads.
{% highlight bash %}
filter_fasta.py -f ${INFILE} -o ${NOCHIM} -s ${GOODSEQIDS}
{% endhighlight %}

Links to the [pipeline PBS script]({{ site.url }}/assets/internal_files/multiple_qsub_chimera_detection.txt) and the [multiple submission shell script]({{ site.url }}/assets/internal_files/multiple_job_submit.txt) that contains the variable names needed


## Testing results and troubleshooting

Following the pipeline there were 43 fasta files present as input and missing from the chimera removal output

{% highlight bash %}
#To count the number of samples used in the input
#path was $HOME/data/qiime_files/all_gom_seqs/ind_fasta_files
find ./ -maxdepth 1 -type f > ../list_of_ind_fasta_files.txt
perl -i.bak -pe 's/.*\/(.*)/$1/g' list_of_final_chim.txt

#To count the output files
find denovo_chimera2/ -regex ".*final.*" -maxdepth 1 > ../list_of_final_chim.txt
perl -i.bak -pe 's/(.*)\.nochim\.final(\..*)/$1$2/g' list_of_final_chim.txt

#Find samples that don't exist in the final_chim file
comm -23 <(sort list_of_ind_fasta_files.txt) <(sort list_of_final_chim.txt)
{% endhighlight %}

Writing a quick bash script to figure out if the fasta files were run but executed with an error
{% highlight bash %}
#!/bin/bash
WORK_DIR=$HOME/job_output_files/;
F_LIST=$HOME/samples_missing_chim_detect.txt
for FILE in $(find $WORK_DIR -type f -regex ".*chimera.*"); do
    for LINE in $(cat $F_LIST); do
	if grep --quiet $LINE $FILE; then
	    echo $FILE
	fi
    done;
done

#No detected files, looks like they just weren't run for some reason? Going to resubmit just them!

#Trying to find the raw fasta files that were skipped
find $HOME/data/qiime_files/all_gom_seqs/ind_samp_seqs/ -maxdepth 1 -type f > full_path_list_all_ind_fasta_files.txt

##################
#!/bin/bash 
mkdir -p "$WORK_DIR/denovo_chimera_fix_failures"
#List of all the individual fasta files
FILE_LIST=$HOME/data/qiime_files/all_gom_seqs/full_path_list_all_ind_fasta_files.txt
#List of those missing from the first round
FAILED_LIST=$HOME/data/qiime_files/all_gom_seqs/samples_missing_chim_detect.txt

#loop over each individual file
for FILE in $(cat $FILE_LIST); do
#loop over each line in the failed list (only 43) & if they match then execute pipeline
    for LINE in $(cat $FAILED_LIST); do
	#echo "current file is $FILE";
	#echo "the matching pattern from failures is: $LINE";
	if [[ $FILE =~ $LINE ]]; then
	    echo $FILE;
	    BASE=${FILE%.fasta}
	    BASE_NAME=$(basename ${FILE%.fasta})
	    BASE="$WORK_DIR/denovo_chimera_fix_failures/$BASE_NAME"
	    qsub -v INFILE=$FILE,OUTFILE="$BASE.derep.fasta",UCFILE="$BASE.uc",NONCHIMFILE="$BASE.nonchimeras.fasta",NONCHIMNONREF="$BASE.nonchim.nonchimref.fasta",MAPFILE="$BASE.uc.map",GOODSEQIDS="$BASE.goodseqids.txt",GOODOTUFILE="$BASE.goodotuids.txt",NOCHIM="$BASE.nochim.final.fasta" job_scripts/multiple_qsub_chimera_detection.pbs
	fi
    done
done
######################

{% endhighlight %}

Dammit, something weird is going on where not all the jobs are getting executed. First time around ~5% of the jobs failed. This time around 11% failed (5 files).

{% highlight bash %}
#$HOME/data/qiime_files/all_gom_seqs/ind_samp_seqs/denovo_chimera_fix_failures
find ./ -name "*.final.*" -type f | perl -pe 's/\.\/(.*)\.nochim.final(.*)/$1$2/g' > ../../samples_missing_2nd_try.txt

comm -23 <(sort ../../samples_missing_chim_detect.txt) <(sort ../../samples_missing_2nd_try.txt) > ../../samples_to_rerun_2nd.txt

#rerun the above bash script modifying the FAILED_LIST to point to "samples_to_rerun_2nd.txt"
{% endhighlight %}

Next I want to move all the *.final.* files to the same directory and delete everything else to clean up my directory (plus it takes forever to loop over!). 
{% highlight bash %}
pwd
#$HOME/data/qiime_files/all_gom_seqs/ind_samp_seqs/denovo_chimera2
find ./ -not -name "*.final.*" -type f -delete

pwd
#
#$HOME/data/qiime_files/all_gom_seqs/ind_samp_seqs/denovo_chimera_fix_failures/
find ./ -not -name "*.final.*" -type f -delete
{% endhighlight %}

Move all the final chimera checked files into the same directory & ensure each original fasta file is accounted for

{% highlight bash %}
find ind_samp_seqs/denovo_chimera2/ -type f > list_chim_checked_fasta.txt
perl -i.bak -pe 's/.*\/.*\/(.*)\.nochim.final(.*)/$1$2/g' list_chim_checked_fasta.txt
#all files that appear in both (result = 890)
comm -12 <(sort list_of_ind_fasta_files.txt) <(sort list_chim_checked_fasta.txt) | wc -l
{% endhighlight %}

## OTU Picking
Although I'm well aware the following is a suboptimal approach after the recent publications from the Schloss lab, I'm stuck with trying to 

{% includes google_analytics %}