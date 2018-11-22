Getting dada2 installed on our new server

1) Create conda environment
conda create -n dada2 zlib=1.2.8
[I needed an older version of zlib for a future error with installing "ShortRead" which was solved thanks to this post, https://support.bioconductor.org/p/108808/]
This actually failed....
Instead trying to install ShortRead through bioconductor. Frankenstein time.
I don't know if this removes the speedup effect you get by natively installing dada2!!
(Below)

2) Install base R version 3.5
For some reason MRO was not working? But then a bunch of stuff wasn't working. It is likely that MRO would be fine with this strategy, I just didn't try after I finally got it working.
conda install -c r r-base=3.5

3) Fix the compiler issues with installing dada2 using Bioconductor (and not Anaconda). This was to try and avoid the 3-20x slowdown in dada2 that Ben Callahan documented [here](https://github.com/qiime2/q2-dada2/issues/74). This fix was provided from this post [here](https://github.com/benjjneb/dada2/issues/417).
conda install gxx_linux-64

4) Install ShortRead through conda
conda install -c bioconda -c conda-forge bioconductor-shortread

5) Fix a resulting shared library issue (why?!)
conda install libiconv

4) Open R & Install dada2
R
install.packages("BiocManager")
BiocManager::install("dada2", version = "3.8")

IT WORKED!!!
