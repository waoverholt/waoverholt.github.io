---
layout: post
title: Playing with R and (ana/mini)conda
excerpt: "Short post for helping an R environment play well with a different R install."
---

This will be a very short post that I am making since I wasn't able to find the answer while googling. I am finally getting around to playing with the [dada2](https://benjjneb.github.io/dada2/index.html) pipeline for gene marker analysis. The motivation for using a conda environment to keep everything organized is to prevent myself from breaking my current R install for a complicated (for me) project that is not yet published. It seems some of my library versions won't play well with eachother and I figure this is a better practice anyways.

So whats the deal?

Well it appears a monkey hacked my system (me) at one point trying to get R to recognize my local directory where I keep R packages. I have two variables permanently sourced in my .bashrc file (R_LIBS & R_LIBS_USER), which I think are redundant for their purpose. I also have a .Renviron file and a .Rprofile file in my home directory that explicitly define R_LIBS and .libPaths(), respectively. Looks like I just threw the book at the problem at one point...

So the problem is R activated from the new conda environment sees my local directory. Unsetting R_LIBS and R_LIBS user is not sufficient as the .Renviron and .Rprofile files have the [highest weight](https://csgillespie.github.io/efficientR/3-3-r-startup.html) in the home directory.

To get around the problem, I added an extremely simple shell script in my conda etc path ($HOME/.conda/envs/myenv/conda/etc/activate.d and ../deactivate.d).
The activate.d/Renviron_fix.sh script looks like this:
{% highlight bash %}
#Remove these environment variables
unset R_LIBS
unset R_LIBS_USER
#overwrite my current .Renviron file when the environment is activated
echo "#R_LIBS=$HOME/data/program_files/R_packages" > $HOME/.Renviron
#add a hash sign to comment out the .Rprofile line that sets .libPaths()
perl -i -pe 's/\.lib/#\.lib/' $HOME/.Rprofile
{% endhighlight %}

The deactivate.d/Renviron_fix.sh script is:
{% highlight bash %}
#source the environment variables (I still think this is unnecessary)
R_LIBS=$HOME/data/program_files/R_packages
R_LIBS_USER=$HOME/data/program_files/R_packages
#revert .Renviron (just remove the hash)
echo "R_LIBS=$HOME/data/program_files/R_packages" > $HOME/.Renviron
#delete the hash in the .Rprofile
perl -i -pe 's/#\.lib/\.lib/' $HOME/.Rprofile
{% endhighlight %}

And now my conda R install doesn't talk to my base install!! Ugly, but functional.
