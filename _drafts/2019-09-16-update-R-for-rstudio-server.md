Updating R for Rstudio Server

(1) Install new version of R from source
Download latest tarball from: https://cran.rstudio.com/src/base/R-3/
Unpack it.

DEACTIVATE any conda enviroments (including "base")

Configure with necessary flags:
```bash
./configure --prefix=$HOME/data/programs/R-3.6.1/bin/ --enable-R-shlib --with-blas --with-lapack --with-x --enable-memory-profiling
make
```

Check all capabilities are installed (png, cairo, pdf, etc...)
```bash
R
capabilities()
```
Current environment looks like this:
       jpeg         png        tiff       tcltk         X11        aqua 
       TRUE        TRUE       FALSE       FALSE       FALSE       FALSE 
   http/ftp     sockets      libxml        fifo      cledit       iconv 
       TRUE        TRUE        TRUE        TRUE        TRUE        TRUE 
        NLS     profmem       cairo         ICU long.double     libcurl 
       TRUE        TRUE        TRUE        TRUE        TRUE        TRUE 




