---
layout: post
title: Processing R1, R2, and Index Files to be used with DADA2
image:
  teaser: shrug.png
excerpt: "Demultiplexing Illumina Sequences from the old 3-file systems. Here specifically to import into dada2 and upload to NCBI."
---
{:toc}

I was contacted by a collaborator about some sequence analysis I had done years ago. I wanted to update that analysis with current best practices and to leaverage the latest classification databases to hopefully improve some of the results. However, I ran into some fun issues where the sequencing facility gave us the reads in 3 files, the forward reads (R1), the reverse reads (R2), and the index reads (I1).
This is a quick summary of how I formatted these files for input into the DADA2 pipeline. I would've had to do this anyways to submit the raw sequences to one of the repositories.

##Using QIIME1 to split libraries and generate the fastq files
OK, so I found out the hardway (QIIME error) that my barcodes were non-golay, 12bp, and were the reverse complement to what was in the mapping file. I ran the split_libraries_fastq.py command this twice, on each direction to keep the read directions separate for DADA2. I also found out the hardway (oops) that you need to disable the error checking in the script to make sure that no sequences are removed. Essentially, if a sequence from R1 is removed and is retained in R2 it'll be difficult to match them back up (at least using the approach listed below, you could always go through and keep only shared sequence identifiers if necessary).
{% highlight bash %}
split_libraries_fastq.py -i Undetermined_S0_L001_R1_001.fastq -b Undetermined_S0_L001_I1_001.fastq --store_demultiplexed_fastq -o R1_out/ -m Kostka_Barcodes_bw_only.txt --barcode_type 12 --rev_comp_barcode -r 1000 -n 1000 -q 0 -p 0.000001

split_libraries_fastq.py -i Undetermined_S0_L001_R2_001.fastq -b Undetermined_S0_L001_I1_001.fastq --store_demultiplexed_fastq -o R2_out/ -m Kostka_Barcodes_bw_only.txt --barcode_type 12 --rev_comp_barcode -r 1000 -n 1000 -q 0 -p 0.000001
{% endhighlight %}

Next we want to split the seqs.fastq file into single fastq files per sample using QIIME1. Nothing fancy here.
{% highlight bash %}
split_sequence_file_on_sample_ids.py -i seqs.fastq --file_type fastq -o ind_R1
split_sequence_file_on_sample_ids.py -i seqs.fastq --file_type fastq -o ind_R2
{% endhighlight %}

## Some sanity checks to make sure we didn't mess up the pair-end orders
Check to make sure they all have the same number of sequences:
I did some really ugly piped bash one-liners to do this. Here is the command in all its unholy glory
{% highlight bash %}
diff <(grep -c "@BW" *.fastq) <(grep -c "@BW" ../../R2_out/ind_R2/*.fastq | sed -e 's/\.\.\/\.\.\/R2_out\/ind_R2\///')
{% endhighlight %}

Basically I'm checking for differences in the number of sequence headers between each file. I tested all the parts individually used head, so something like:
{% highlight bash %}
grep -c "@BW" BW-001.fastq | head
grep -c "@BW" ../../R2_out/ind_R2/*.fastq | head
#The sed command is used to remove the path for the R2 reads, so the file names will match
grep -c "@BW" ../../R2_out/ind_R2/*.fastq | sed -e 's/\.\.\/\.\.\/R2_out\/ind_R2\///' | head
...
{% endhighlight %}
Because the file names are the same in each directory, the default sort puts them in the same order. If this wasn't true, just add a ```sort``` command to your pipe. To furtehr break it down, I'm running two grep -c (count) on each set of folders. I do a super ugly substitution to remove the path of the files in the different directory with sed (backslash to escape the period and forwardslash special characters).

## Check to make sure that the paired-end sequences are in the same order
I modified the above ```diff``` to compare the fastq sequence identifiers. My sequence headers look like this: 
@BW-001_2174333 M00176:78:000000000-A3M8L:1:2114:15243:27709 1:N:0:0 orig_bc=CAGCTCATCAGC new_bc=CAGCTCATCAGC bc_diffs=0
So I grab only this part:
M00176:78:000000000-A3M8L:1:2114:15243:27709
{% highlight bash %}
diff <(grep "^@BW" *.fastq | cut -d" " -f 2) <(grep "@BW" ../../R1_out/ind_R1/*.fastq | sed -e 's/\.\.\/\.\.\/R2_out\/ind_R2\///' | cut -d" " -f 2)
#cut -d" " tells cut to split the line into columns (elements) based on a space
#cut -f2 tells cut to give me the 2nd column

#Could also use the cmp command which will give you the first position that is different to track down errors
cmp <(grep "^@BW" *.fastq | cut -d" " -f 2) <(grep "@BW" ../../R1_out/ind_R1/*.fastq | sed -e 's/\.\.\/\.\.\/R2_out\/ind_R2\///' | cut -d" " -f 2)
{% endhighlight %}

## Bonus work on sorting paired-end reads based of their illumina identifier
OK, so the first time I did this, I didn't catch that error checking would mess up the paired-sequences. I stupidly thought one of the scripts ended up shuffling the sequences (maybe read them into a dictionary or something?), but regardless the sequences looked completely shuffled. I had to work out a way to resort the files based on the illumina-based sequence identifier. 
{% highlight bash %}
mkdir sorted
for file in $(ls ./ | grep "fastq"); do cat $file | paste - - - - | sort -k2,2 | head | tr "\t" "\n" > sorted/$file; done
{% endhighlight %}

The key step here is this command:
{% highlight bash %}
cat $file | paste - - - - | sort -k2,2 | tr "\t" "\n" > sorted/$file;
#$file is one of our unsorted fastq files that looks like this:
@BW-001_22 M00176:78:000000000-A3M8L:1:1101:13034:2361 1:N:0:0 orig_bc=CAGCTCATCAGC new_bc=CAGCTCATCAGC bc_diffs=0
TACGGAGGGGACGAGCGTTGTTCGGAATTACTGGGCGTAAAGGGCGCGTAGGCGGCCTGACCAAGTCGGGTGTGAATGCCCTCGGCTCAACCGAGGACTTGCACCCGATCCTGGTTGGCTAGAGTCCGGGAGGGGGTAGCGGAATTCCCAGTGTAGCGGTGAAATGCGTAGATATTGGGAAGAACACCGGTGGCGAAGGCGGCTACCTGGACCGGTACTGACGCTGAGGCGCGAAAGCCAGGGGCGCGAAT
+
AAAA@1>1>D?AAE0AAAEFF/F??BABAAAFFFHHEGGGGF1EF/>@@EEEFEEGCGGBGGE?<1>??/?/>CGH22BG0</C/</?F1?</<<-C.F11=GDGA-<-<.D0//;EACG0C0:G:GCC?-?--@@AF?F@@?-ABF/B/9BFBFFF@@A?EFFFFFF-9--BBFBF/EFB--;;9BB;@--:A=-@@-A-99@-9BF/F-;F@@@@BBF/BFBB9-AFE-@--;--;-;-:B@-9--;9-
@BW-001_67 M00176:78:000000000-A3M8L:1:1101:18131:2408 1:N:0:0 orig_bc=CAGCTCATCAGC new_bc=CAGCTCATCAGC bc_diffs=0
TACGGAGGGTGCAAGCGTTAATCGGAATTACTGGGCGTAAAGCGCGCGTAGGCGGTTGATTAAGTCGGATGTGAAAGCCCTGGGCTTAACCTGGGAACTGCATTCGATACTGTTCGACTAGAGTACGAGAGAGGGAGGTAGAATTCCACGTGTAGCGGTGAAATGCGTAGATATGTGGAGGAATACCGGTGGCGAAGGCGGCCTCCTGGCTCGATACTGACGCTGAGGTGCGAAAGCGTGGGGAGCAAACC
+
BAABAAADDBBAGEGFAEEEFGFFFE2FHGHHGHFHGEGGCHHEGAEEECEGGEGFGEFFHGDEFGAEGGGHHBGDBBFGFHHF?CFFFGHGHFGAGFBGGGHFFFFHGGHGHHHG/FGAHEHGEFGFDADGGGGGGGEFHFFFGHHHHGHHHHB;ACEGGFFGGGGAAAGF;FFGGGGGG.BB0CBDD=;D9DCAABA@BFFFFFFFFFFFCDFEBFFBFFFFD.9AFFBD;@B9BDDDAFF9B9.;BF.

#To deconstruct this statement:
paste - - - -
#Takes 4 lines in at a time and separates them by tab (so now I can sort the 4 line sequence together based on the first line)
sort -k2,2
#Sort based on the 2nd column to the 2nd column, so only M00176:78:000000000-A3M8L:1:1101:13034:2361.
tr "\t" "\n" > sorted/$file
#Replace the "tabs" with "new lines" to split the fastq sequence back into 4 lines (reverse the paste command).
{% endhighlight %}
Then I wrap it in a loop to process every fastq file separately and save the results in a new directory called "sorted".

Fix the sequence numbering.
I actually don't think this matters? But it is SUPER confusing since the QIIME assigned sequence IDs don't match up (but the sequence identifiers do, which is all that matters). Definitely worth convincing yourself this is true, because it would be a disaster is the reads randomly were joined.
Regardless I'm going to use a perl loop to quickly renumber my sequences. Note, the regex I'm using is very specific to this sample set.
{% highlight bash %}
perl -ne 'BEGIN {$i=0}; if ($_ =~ m/^\@BW-[0-9]{3}/) {($identifier = $_) =~ s/(BW-[0-9]{3}_)[0-9]+/$1$i/; print $identifier; $i++} else {print $_}' BW-001_R2.fastq
{% endhighlight %}
The m/^\@BW-[0-9]{3}/ matches my sample names for every sample. Basically says, if the line starts with @BW- and then has a number with 3 digits (000-999). My samples are named BW-001 through BW-199.
You would need to change the s/(BW-[0-9]{3}_)[0-9]+/$1$i/ code as well. Here I place the BW-[0-9]{3}_ within parentheses to "save" this, then I replace the next number (any number of digits) with my counter, $i.

You can pipe this to a new file, or use the perl -i operator to do it in place. You want to only do this when you're sure that you're loop is working!
Here's how I loop it through my files.
{% highlight bash %}
for file in $(ls ./ | grep fastq); do perl -i -ne 'BEGIN {$i=0}; if ($_ =~ m/^\@BW-[0-9]{3}/) {($identifier = $_) =~ s/(BW-[0-9]{3}_)[0-9]+/$1$i/; print $identifier; $i++} else {print $_}' $file; done
{% endhighlight %}

## Primer Trimming

