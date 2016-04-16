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

After working on this for awhile, I stumbled across a blog maintained by [Amanada](http://agelmore.github.io/). I borrowed fairly heavily from some of her experiences and examples. I recommend you check it out, lots of nice, clear posts!

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
{% endhighlight %}
{% comment %}
<style>
table{
    border-collapse: collapse;
    border-spacing: 0;
    border:2px solid #ff0000;
}

th{
    border:2px solid #000000;
}

td{
    border:1px solid #000000;
}
</style>
{% endcomment %}

Dataset|Time|Test|
-------|:----:|----:|
1%     |13m34|test|
10%    |161m24|test|

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


## MetaVelvet
A comparison wouldn't be right without including [MetaVelvet](http://metavelvet.dna.bio.keio.ac.jp/){:target="_blank"}. I had experience using Velvet for single genome assembly during my [Computational Genomics class](http://compgenomics2013.biology.gatech.edu/index.php/Main_Page) and MetaVelvet is well represented in the literature.

Like the above two assemblers, MetaVelvet constructs de Bruijn-graphs to link connected sequences.

Since I'm mostly in the exploratory phase (avoiding getting bogged down and overwhelmed), I'm not planning on testing the supervisted-learning MetaVelvet module at this time. Furthermore, there really aren't that many genomes available for the environments I will be working on so getting the model might end up making things worse.

{% highlight bash %}
cd $HOME/data/program_files
wget http://metavelvet.dna.bio.keio.ac.jp/src/MetaVelvet-1.2.02.tgz
tar -zxvf MetaVelvet-1.2.02.tgz
{% endhighlight %}

I wasn't sure good max kmer size or category sizes to use so I just ran make and it seemed to work. May have go back and re-compile at a future date. Looks like the default values are: MAXKMERLENGTH=63, CATEGORIES=2
{% highlight bash %}
make
{% endhighlight %}

The make succeeded with no errors. However, I needed to read more carefully and install Velvet as well.

{% highlight bash %}
git clone https://github.com/hacchy/velvet
make

#Make symbolic links to all the executable files so they are in my $PATH
ln -s /nv/hp10/woverholt3/data/program_files/velvet/velvetg /nv/hp10/woverholt3/bin/velvetg
ln -s /nv/hp10/woverholt3/data/program_files/velvet/velvetg /nv/hp10/woverholt3/bin/velvetg
ln -s /nv/hp10/woverholt3/data/program_files/MetaVelvet-1.2.02/meta-velvetg /nv/hp10/woverholt3/bin/meta-velvetg
{% endhighlight %}

## QUAST
Evaluating Metagenomic Assemblies

{% highlight bash %}
wget https://downloads.sourceforge.net/project/quast/quast-3.2.tar.gz
tar -xzf quast-3.2.tar.gz
cd quast-3.2

python metaquast.py --test-no-ref
{% endhighlight %}

## Testing percent of reads used in the assembly




