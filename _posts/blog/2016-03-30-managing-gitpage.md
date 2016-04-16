---
layout: post
title: Managing this website with Git and Github
image:
  teaser: github-logo.jpg
excerpt: Hosting this website on Github and working with git version control.
---
* Table of Contents
{:toc}

While I have some experience playing around with git, I never actually fully incorporated it into my workflows. As this is a skill I want to learn and utilize (I've messed up a script so many times in the past and been unable to figure out what the hell I changed) I figured this would be a good venue to start with. I'm in the middle of updating my static html personal website, to one based on Jekyll with a theme provided by Minimal Mistakes (so-simple), and I'm working on new (for me) metagenomic workflows and have written a few summary scripts in this regards.

This entry will likely be read by me every time I add a new blog entry to this website as it concerns hosting both my websites source files, and the production ready site. I followed David Ensinger's post [Deploying Jekyll with Plugins to GitHub Pages](http://davidensinger.com/2013/04/deploying-jekyll-to-github-pages/) to start (nearly verbatium at parts).

## Setting up my Jekyll Page on Github
Initializing the git repository.
{% highlight bash %}
git init
{% endhighlight %}

Create a branch called source (this will be my main jekyll site)
{% highlight bash %}
git checkout -b source
{% endhighlight %}

Add a .gitignore file to my main site directory containing _site (as recommended by Jekyll).

Delete my old branch "master" (I don't know if this is necessary)
{% highlight bash %}
git branch -D master
{% endhighlight %}

Create a new branch "master" 
{% highlight bash %}
git checkout -b master
{% endhighlight %}

Make the default project root of this branch be _site (the static jekyll built site)
{% highlight bash %}
git filter-branch --subdirectory-filter _site/ -f
{% endhighlight %}

Switch back to the source branch (again this may be unnecessary)
{% highlight bash %}
git checkout source
{% endhighlight %}

Push all branches (source, master) to origin (my github repository)
{% highlight bash %}
git push --all origin
{% endhighlight %}

## Updating a development version of the site
Make sure I'm working on the development branch
{% highlight bash %}
git checkout development
{% endhighlight %}

Make changes to files. Best practice to git add & git commit everytime you change something. So frequently use the following commands
{% highlight bash %}
git status
git add <file>
git commit -m "message"
{% endhighlight %}

Test my local version of the website. I have bundle installed so I run:
{% highlight bash %}
bundle exec jekyll serve
{% endhighlight %}


## Updating my production site
After I'm happy with the content I've added and tested on my development site. I checkout my master branch, the merge the development changes. I also do the same with my source branch. This seems very redundant to me and there is likely a better way of doing this!

{% highlight bash %}
git checkout master
git merge development

git checkout source
git merge development

git push --all
{% endhighlight %}

An easier way to update both master and source from the development.
{% highlight bash %}
git checkout development
git pull . development
{% endhighlight %}

{% includes google_analytics %}