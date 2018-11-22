---
layout: post
title: Installing rstudio and dada2 on our new server
image:
  teaser: Anaconda_Logo.png
  creditlink: https://docs.anaconda.com/
excerpt: "Troubleshooting to install dada2 and rstudio on our local server using conda."
---
* Table of Contents
{:toc}

Getting dada2 installed on our new server

## Create conda environment
{% highlight bash %}
conda create -n dada2 zlib=1.2.8
{% endhighlight %}
I needed an older version of zlib for a future error with installing "ShortRead" which was solved thanks to this [post](https://support.bioconductor.org/p/108808/)
This actually failed....
Instead trying to install ShortRead through bioconductor. Frankenstein time.
I don't know if this removes the speedup effect you get by natively installing dada2!!
(Documented Below)

## Install base R version 3.5
For some reason MRO was not working? But then a bunch of stuff wasn't working. It is likely that MRO would be fine with this strategy, I just didn't try after I finally got it working.
{% highlight bash %}
conda install -c r r-base=3.5
{% endhighlight %}

Fix the compiler issues with installing dada2 using Bioconductor (and not Anaconda). 
This was to try and avoid the 3-20x slowdown in dada2 that Ben Callahan documented [here](https://github.com/qiime2/q2-dada2/issues/74). This fix was provided from this [post](https://github.com/benjjneb/dada2/issues/417).
{% highlight bash %}
conda install gxx_linux-64
{% endhighlight %}

Install ShortRead through conda
{% highlight bash %}
conda install -c bioconda -c conda-forge bioconductor-shortread
{% endhighlight %}

Fix a resulting shared library issue (why?!)
{% highlight bash %}
conda install libiconv
{% endhighlight %}

## Open R & Install dada2
{% highlight bash %}
R
{% endhighlight %}
{% highlight R %}
install.packages("BiocManager")
BiocManager::install("dada2", version = "3.8")
{% endhighlight %}

## Install rstudio
Somehow this worked as well!
{% highlight bash %}
conda install -c r rstudio
{% endhighlight %}

## Final Notes
I really should have spent the time to figure out Rstudio Server and get that running. It would probably be smoothly than using this desktop version. However, we were on a time crunch and this seems to be keeping everyone happy for now!

