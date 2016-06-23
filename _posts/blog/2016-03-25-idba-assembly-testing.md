---
layout: post
title: Testing Metagenomic Assemblers
image:
  teaser: de_bruign_graph.jpg
  credit: Berger et al., 2013, Nature Rev. Genetics
  creditlink: http://www.nature.com/nrg/journal/v14/n5/fig_tab/nrg3433_F1.html
excerpt: "Testing out and learning to use some Metagenomic assemblers. Starting with IDBA-UD, SPAdes, and Velvet. Will be progressing to binning and de novo genome construction next." 
---
* Table of Contents
{:toc}

<style>
table{
    border-collapse: collapse;
    border-spacing: 0;
    border:2px solid #000000;
}

th{
    border:2px solid #000000;
}

td{
    border:1px solid #000000;
}
tr:nth-child(even) {
    background-color: #ccc;
}
</style>

After working on this for awhile, I stumbled across a blog maintained by [Amanda](http://agelmore.github.io/). I borrowed fairly heavily from some of her experiences and examples. I recommend you check it out, lots of nice, clear posts!

## IDBA-UD
I am planning on generating fairly large metagenomic and metatranscriptomic datasets within the next few months. Since I have a little bit of down time while some 16S datasets run through my pipeline, I thought I'd play around with some simulated and publicly available datasets.

One of my good friends recommended starting with [IDBA-UD](http://i.cs.hku.hk/~alse/hkubrg/projects/idba_ud/). I thought I'd try this medium to record my experiences as I'm in the middle of updating my personal website as well.

Installing IDBA:
{% highlight bash %}
git clone https://github.com/loneknightpy/idba
cd idba
./build.sh
{% endhighlight%}

Using the author's simulated datasets to test the install
{% highlight bash %}
#Copy the provided data files, un-tar them, and enter the directory
wget http://hku-idba.googlecode.com/files/lacto-genus.tar.gz
tar -zxvf lacto-genus.tar.gz
cd lacto-genus

#Run the sim_reads command as provided by the authors
sim_reads sim_reads 220668.fa 220668.reads-10 --paired --depth 10 & sim_reads 321956.fa 321956.reads-100 --paired --depth 100 & sim_reads 557433.fa 557433.reads-1000 --paired --depth 1000 

#concatenate the simulated files into "meta.fa"
ls | grep "reads" | xargs -I file cat file >> meta.fa

#Test the idba_ud command
idba_ud -r meta.fa -o idba_meta_assembly

{% endhighlight %}

Testing on a different dataset
Using only sample BP101

Using multiple different sizes:
{% highlight bash %}
head -n 51855188 BP101.CoupledReads.fa > BP101_10.fa &
head -n 5185518 BP101.CoupledReads.fa > BP101_1.fa &

#$INPUT=BP101.CoupledReads.fa, BP101_10.fa, BP101_1.fa
#$OUTPUT=idba_full_mason_seqs, idba_bp101_1, idba_bp101_10
time idba_ud -r $INPUT --pre_correction -o $OUTPUT --num_threads $PROCS

calc_contig_stats.py -i contig.fa -r ../BP101_CoupledReads.fa
{% endhighlight %}

[idba_ud pbs script]({{ site.url }}/assets/internal_files/idba_ud.pbs)
[calc_contig_stats.py]({{ site.url }}/assets/internal_files/calc_contig_stats.py) is a little script I wrote that calculates a few of the assembly values I'm interested in, names:
			  - Number of Contigs
			  - N50 value
			  - Length of longest contig
			  - Mean contig size
			  - Number of contigs > 1kb
			  - Percent of reads used to make assembly

## SPAdes
[SPAdes](http://bioinf.spbau.ru/spades){:target="_blank"} is another fairly recent assembler that has options to handle metagenomic datasets. It comes pre-packaged with linux binaries that I was able to use out of the box, always nice.

Installing using the guidelines provided:
{% highlight bash %}
wget http://spades.bioinf.spbau.ru/release3.7.1/SPAdes-3.7.1.tar.gz
tar -zxvf SPAdes-3.7.1.tar.gz
cd SPAdes-3.7.1

{% endhighlight %}
Adding the scripts to my path:
{% highlight bash %}
emacs ~/.bashrc
export PATH=$PATH:$HOME/data/program_files/SPAdes-3.7.1/bin
source ~/.bashrc
{% endhighlight %}

Running the provided test scripts:
{% highlight bash %}
spades.py --test
{% endhighlight %}

Running my 1% dataset:
{% highlight bash %}
spades.py -o spades_bp101_1 --meta --12 BP101_1.fa --only-assembler
{% endhighlight %}

[spades pbs script]({{ site.url }}/assets/internal_files/spades.pbs)

## Megahit
Another de Bruijn graph assembler that was created specifically for large complex metagenomic datasets. It has the option to use a GPU to increase the speed of the assembly, but I haven't tried this out yet.

Installing Megahit
{% highlight bash %}
git clone https://github.com/voutcn/megahit.git
cd megahit
make
{% endhighlight %}

Testing Megahit on the 1% dataset
{% highlight bash %}
$HOME/data/program_files/megahit/megahit -12 $INPUT -o $OUTPUT -t $PROCS --presets meta-large

{% endhighlight %}
[megahit pbs script]({{ site.url }}/assets/internal_files/megahit2.pbs)

## QUAST
Evaluating Metagenomic Assemblies

{% highlight bash %}
wget https://downloads.sourceforge.net/project/quast/quast-3.2.tar.gz
tar -xzf quast-3.2.tar.gz
cd quast-3.2

python metaquast.py --test-no-ref

metaquast.py --max-ref-num 0 --threads 10 contig.fa

cat quast_results/latest/report.txt
{% endhighlight %}

## Results to date

| |IDBA_UD_1%|IDBA_UD_10%|IDBA_UD_100%|SPAdes_1%|SPAdes_10%|SPAdes_100%|Megahit_1%|Megahit_10%|Megahit_100%|
-------|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|----:|
Time|13m34|161m24|FAILED|59m32|997m25|FAILED|11m40|167m34|701m21|
Memory (Gb)| | |192| | |102| | |48|
Contigs|1,834|62,749| |15,074|304,115| |1,430|64,320|771,306|
Contigs > 500bp|363|16,005| |273|12,043| |250|12,211|166,899|
Contigs > 1kb|68|3,023| |43|1,845| |44|1,955|35,348|
N50|414|459| |237|257| |387|405|442|
N50 (>500bp)|818|809| |736|744| |771|759|883|
Max Contig|5,485|24,394| |5,441|22,375| |5,473|14,971|71,426|
Mean Contig|453|487| |224|267| |409|422|460|
Total Length (>500bp)|306,037|13,467,620| |213,926|9,558,868| |200,843|9,691,657|152,384,054|
Percent Reads Used|2.7|9.7| |4.8|14.7| |2.2|9.6|23.7|

IDBA_UD and SPAdes keep running out of RAM on the full dataset. We only have 2 high memory nodes on our cluster, so they've bee in queue for awhile now waiting for enough ram. I'll update the table with the results.

However, I'm pretty happy with Megahit. Much more efficient memory usage, CPU times are very similar to IDBA_UD, and the stats are similar (slightly lower % reads used, slightly shorter contigs on average, the longest contigs tend to be shorter etc...) However, I am not benchmarking these aligners with mock datasets, so I don't know the fidelity of the contigs.

Also, I stumbled across [Dr. Titus Brown's blog](http://ivory.idyll.org/blog/category/personal.html) again, and his group [recommends](http://ivory.idyll.org/blog/2016-partitioning-no-more.html) using Megahit, with a review found [here](http://ivory.idyll.org/blog/2014-how-good-is-megahit.html)

## CONCOCT binning
I will probably end up moving this to a new blog post, but since this one is currently open I'll put the text here for now.

I'm installing CONCOCT on our cluster using anaconda

{% highlight bash %}
# Installing dependencies

#bedtools2
git clone https://github.com/arq5x/bedtools2
cd bedtools2
make

#gnu parallel - availabe on our cluster already
module load gnuparallel/20150422

#samtools - already installed

#bowtie2 - already installed

#blast - already installed

#picard - available on cluster
module load picardtools/1.93

#Installing CONCOCT
module load anaconda2/2.1.0
conda create -n concoct_env python=2.7.6

source activate concoct_env

conda install cython numpy scipy biopython pandas pip scikit-learn

git clone http://github.com/BinPro/CONCOCT

python setup.py install
{% endhighlight %}

### Running CONCOCT
I'm following the [full example](https://concoct.readthedocs.io/en/latest/complete_example.html) provided by the CONCOCT developers.

Setting up the environment:
{% highlight bash %}
module load gnuparallel/20150422; module load picardtools/1.93; module load samtools; module load anaconda2/2.1.0
source activate concoct_env

CONCOCT=$HOME/data/program_files/CONCOCT/
export MRKDUP=/usr/local/packages/picardtools/1.93/lib/MarkDuplicates.jar
export PATH=$PATH:$HOME/data/program_files/bedtools2/bin
{% endhighlight %}

Cut up the contigs (using the megahit assembly of the 10% dataset)
{% highlight bash %}
cd ~/scratch/megahit_bp101_10/
mkdir concoct
cd concoct

#-c = chuck size, -o = overlap size, -m = flag, concatenate final part to last contig
$CONCOCT/scripts/cut_up_fasta.py -c 10000 -o 0 -m ../final.contigs.fa > final.contigs_c10k.fa
{% endhighlight %}

Mapping the raw reads back onto the contigs to estimate coverage of each contig.

I need to feed the CONCOCT script non-interleaved fasta files. Unfortunately, I don't have the raw files that were used to make the interleaved ones. Here is a quick perl based one-liner that splits your file into R1 and R2 depending on /1 or /2 at the end of the sequence head. 

Basically, check if the header has a /1 or /2, if so, print the next line. I don't bother moving ahead 2 lines since I don't need it optimized. 
{% highlight bash %}
perl -ne 'BEGIN {$next = 0;} if ($next > 0) {print $_; $next = 0;} else {if ($_ =~ m/\/2/) {print $_; $next = 1;} }'
{% endhighlight %}

{% highlight bash %}
bowtie2-build final.contigs_c10k.fa final.contigs_c10k.fa

/nv/hp10/woverholt3/data/program_files/CONCOCT/scripts/map-bowtie2-markduplicates.sh -ct 1 -p '-f' ../../BP101_10_R1.fa ../../BP101_10_R2.fa pair final.contigs_c10k.fa asm bowtie2
#pair = name for the sample used (name refering to R1 & R2)
#asm = name of the assembly used
#results in a file: "assembly_name"_"pair_name".*

python /nv/hp10/woverholt3/data/program_files/CONCOCT/scripts/gen_input_tab
le.py --isbedfiles --samplenames samplename.txt ../final.contigs_c10k.fa asm_pair-smds.coverage > concoct_inputtable.tsv

cut -f1,3- concoct_inputtable.tsv > concoct_inputtableR.tsv

concoct -c 40 --coverage_file bowtie2/concoct_inputtableR.tsv --composition_file ../final.contigs.fa -b concoct_output/

{% endhighlight %}
{% include google_analytics.html %}