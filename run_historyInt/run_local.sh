#!/bin/bash 

# create a mesh for interpolation first
casename=duct
rm  -f $casename.sch
echo $casename > SESSION.NAME
echo $PWD/ >> SESSION.NAME

rm log_*

mpirun -n 4 ./nek5000 | tee log_01.txt

mv history2.txt ZSTAT/
