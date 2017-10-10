---
layout: post
title: Snakemake pipeline for 16S rRNA amplicon analysis
excerpt: "Trying to simplify my hacked together analysis pipeline with something a little more robust. Plus I've been wanting to play with snakemake for a long time now."
---
* Table of Contents
{:toc}

## Installing the pipeline
I have now hosted all files on a public github project [snakemake_16S_pipeline](https://github.com/waoverholt/snakemake_16S_pipeline).
The README file has information about installing everything, but essentially you need python3, miniconda, and snakemake.

First clone the [github repository](https://github.com/waoverholt/snakemake_16S_pipeline).
{% highlight bash %}
mkdir path/to/new/directory
cd path/to/new/directory
git clone https://github.com/waoverholt/snakemake_16S_pipeline
cd snakemake_16S_pipeline
conda env create -n snakemake_16S python=3.5 --file environment.yaml
{% endhighlight %}

If everything worked, you should have a virtual environment named "snakemake_16S" that contains all necessary dependencies.
To start it:
{% highlight bash %}
source activate snakemake_16S
#if conda isn't in your path you need to specify it
source /path/to/conda/install/bin/activate snakemake_16S
{% endhighlight %}

## Preformating sequence library names
The pipeline assumes you have paired end libraries, which each sample pair in a different file.
E.G. "sample1_R1_001.fastq.gz"
The extensions can be changed in the config.yaml file.

You may wish to do some initial name cleaning before running the pipeline.
E.G. I changed my sample names from WAO_T0C1_S112_L001_R1_001.fastq.gz to WAO_T0C1_R1_001_fastq.gz

## Initial configuration & parameters
Check out the config.yaml file. Here you can specify specifics for your sample set.
Change the paths for:
read_directory:
chimera_db:

You may want to change the threads to match your system.

The oligos file should be in the "additional_files" directory, but you can change this path if you need to.

## Running snakefile
To start the pipeline simply type:
{% highlight bash %}
snakemake --configfile config.yaml --snakefile Snakefile
{% endhighlight %}
If you'd like to run the pipeline with some steps in parallel, specify the number of threads available with:
{% highlight bash %}
snakemake --configfile config.yaml --snakefile Snakefile -j 7
{% endhighlight %}
