#!/bin/bash

INDIR=$HOME

for FILE in $(find $INDIR -type f -name "*CoupledReads*");
do
    qsub -v INFILE=$FILE $HOME/multiple_qsub_subsample.pbs
done
