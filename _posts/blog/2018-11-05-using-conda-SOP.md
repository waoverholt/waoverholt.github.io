# Using Conda to Manage your Environments and Programs
Everything you could ever want to know can be [found in the anaconda documents](https://conda.io/docs/user-guide/index.html). This will just serve as a very quick guide on installing programs using conda and keeping your account /computer nice and organized without conflicts.

So what is Conda you ask? Well these posts [1](https://jakevdp.github.io/blog/2016/08/25/conda-myths-and-misconceptions/) [2](https://medium.freecodecamp.org/why-you-need-python-environments-and-how-to-manage-them-with-conda-85f155f4353c) cover a lot more information that I will.

But in laymen's (my) terms, conda has become a super handy way of managing a bunch of software as painlessly as possible. While orginally used just to manage python environments, you can now use conda to manage software packages that use a bunch of different programming languages. For example, [google conda blast](http://lmgtfy.com/?q=conda+blast).  
You'll see that you can install blast version 2.7.1 with the command:
```
conda install -c bioconda blast
```
AMAZING right.  

Go ahead and search for your favorite (mostly non-GUI) programs.

Here's my current list of my work computer: **Qiime v1, Qiime v2, mothur, dada2, spades, IDBA, megahit, metabat, das tool, bowtie, bbmap, prokka, maxbin, binsanity, anvio, Rstudio**...

## Conda on our new LUMOS server
Since we're starting from scratch and had great feedback from y'all, Calle and I have Conda configured for multiple users. This basically means, we have 1 version of miniconda (see section below) that everyone can access. People with login information for the conda account, can install environments that everyone can use. If the whole group likes to use a specific program routinely, it'll be a good idea to install that here, so we all end up using the same version! *Also, if you just f***ing hate the commandline we'll be happy to get a program installed for you. *As a warning, you will be preached at when you come and ask for a program to be installed simple because you don't like the command line. If the program is not on a conda repository we will still preach at you, but will be happy to get it installed as well.* 

Some starting notes:  
When your username was created, we should have make some initial configurations to make everyones life easier. These involve giving you direct links to our large, backed-up, hard-drives as well as a very fast temporary file storage drive. We also gave you access to the system conda location, and it should be available by simply typing:
```
conda
```
If this doesn't do anything, come talk to us. If you get a help menu, great!!

### Using a system-wide Conda Environment
Think of these as your pre-installed programs available at a few clicks of the keyboard.
To see what pre-installed environments are available simply type:
```conda info --envs```
This will be a list of all conda environments you can access as well as their location. The system environments for everyone are in /opt/miniconda3/envs

To activate an environment (read this as, "use a program"):
```
conda activate <name>
```

To stop using an environment
```
conda deactivate
```
(Or if you're done, just close the terminal)

### Managing your very own environments
Maybe you are the master of your own programs (dammit!) or you can't wait around for those lazy admins to install something for you. No problemo! Us lazy admins were nice enough to create your very own conda configuration file that will install local (your) environments under ~/data/programs/conda
*Note, if you don't like this, simply change the setting in your ~/.condarc file. Just FYI, the default location is ~/.conda/ *

To create your environment
```
conda create -n <environment_name>
```
To install packages / programs into that environment
```
conda activate environment_name
conda install -c <repository> <package1> <package2>
conda install -c <repository2> <package3>
...
```

Or in one fell swoop
```
conda create -n <env_name> -c <repository1> -c <repository2> <package1> <package2> <package3>
conda activate env_name
```

### Common repositories to search in
  - bioconda
  - conda-forge
  - r-essentials
  - r

*Honestly, just google it.*

## What about our other servers?!?!
Be the change that you want to see in the world!  

Or convince someone else to be that change, the world is you oyster.

Worst case scenario, install miniconda on your local user account and screw the system.

**What about my computer?**
What about it, go and install conda and be happy!! Conda is available for all major OS's. But programs for linux will not run on a PC regardless if conda is there...nice try.

## Last Thoughts
For the love of all that is holy in this world, if your program needs **GIANT DATABASES** (I'm looking at you Kaiju) please talk to us. This is still in development, but on LUMOS there is a folder at /data/databases/ that is group accessible. Please check here first!! But an expensive way to fill up a server is 5 copies of NR installed in various places.  
If the database you need is not in /data/databases, then check again. If you are very sure **and you are very confident that you won't destroy this directory**, then go ahead and install what you need. If you delete someone's database by mistake, I'm pretty sure they'll be unhappy. If you ask an admin to install that database for you, and WE mess it up, they can be angry at US and you're in the clear. You've been warned.


## Why miniconda and not anaconda?
I'm glad you asked! Miniconda gives you the base conda functionality with no pre-installed programs. Anaconda gives you a huge bloated set of programs, most of which you'll probably never use (I have a lot of bias here). Miniconda gives you the power to decide what programs to have and how to set them up.

## Setting up our new server for miniconda with multiple users
I basically followed someone else's handy post, [thanks Peter Roche](https://medium.com/@pjptech/installing-anaconda-for-multiple-users-650b2a6666c6).


Creating a miniconda admin user:  
```
sudo adduser conda
```
I didn't give this user admin rights to the server, so I did the rest of the steps from my account.  

Downloading miniconda
```
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
#fix permissions
chmod u+x Miniconda3-latest-Linux-x86_64.sh
./Miniconda3-latest-Linux-x86_64.sh
```
Make sure to select the installation folder to /opt/miniconda3

Change ownership over to our conda account
```
chown -R conda:conda /opt/miniconda3
```
Prevent non-admin users from installing system wide environments
```
chmod -R go-w /opt/miniconda3
```
But give everyone in the group access to system enviroments
```
chmod -R go+rx /opt/miniconda3
```

### Installing system wide environments
```
conda create -n <environment name> -c <repository> <package1> <package2> <package3>...
```

### Setting up USER for access to system conda
Basically create the same .condarc file for each user. We place their own conda enviroments in our data partition instead of home since it is MUCH larger. 
```
echo "envs_dirs:
  - /home/<username>/data/programs/conda" >> .condarc
```
Now the user can use
```
conda activate <environment_name>
```
Or can install their own environments in ~/data/programs/conda simply with
```
conda create -n <environment_name>
```



