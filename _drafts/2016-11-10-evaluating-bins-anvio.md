---
layout: post
title: "Testing Megahit metagenomic assembly & binning approachs on subsampled metagenomes"
excerpt: "I'm using what I learned from the metagenomic assembly testing to do a more involved run on a subset of the data while I wait for resources on the cluster to become available to run the full dataset."
---

* Table of Contents

{:toc}

Anvi'o has been a program I've been meaning to test for a long time now. It is a full interactive pipeline that comes from the [Meren lab](http://merenlab.org/) up at the University of Chicago.

I'm mostly interestedin Anvi'o's visualization capabilities and I'm planning on trying to load the [DeepC metagenome assembly]{% post_url 2016-06-23-metagenomic-assembly-binning %} that I discuss in another amalgamation post.

I installed Anvi'o on both GATech's cluster and my work computer fairly easily following the [online instructions](http://merenlab.org/2016/06/26/installation-v2/). In both cases I started a new virtual environment and added the necessary prerequists to the [postactivate hook]({{ site.url }}/assets/interal_files/anvio_postactivate.txt) file in the virtualenv. A few of the programs were installed in my system path and on the cluster I was able to leaverage a few modules that PACE kindly provided.

I still need to workout how to interactively work on clusters work nodes (currently get blocked when I try [this approach](http://merenlab.org/2015/11/28/visualizing-from-a-server/), but it works fine for tunneling to the headnode.

Other than that, I'm currently just following [this tutorial](http://merenlab.org/2016/06/22/anvio-tutorial-v2/) and working out the kinks as I go along.

One of the first kinks I hit was how long it took to predict coding regions with prodigal without multithreading. Reading a bit on the [prodigal wiki](https://github.com/hyattpd/prodigal/wiki) their -p anon (-p meta in the version with anvio) mode can be easily parallelized.

So I'm currently working on the below flow:
1. Generate the Anvio contigs database and skip gene calling.
2. export the soft-split contigs
3. split this file into chunks of 10,000 seqs
4. run prodigal on each chunk
5. merge the resulting .faa files together
6. use my convert_prodigal_to_anvio.py script that is entirely hacked from Meren's "prodigal.py" script.
7. update the contigs.db database

I need to check and see if this is actually faster...

One thing I've noticed is the import gene calls seems to be pretty slow. 