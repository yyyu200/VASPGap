# VASPGap
====  
Find the VBM from EIGENVAL of VASP output, supporting spin-polarized and noncollinear cases.

use -c or -n for collinear/noncollinear results, otherwise the code may guess one (but maybe not right!)


Usage:  
Gap.sh [-f FILENAME -n -c -h ]  
    -f FILENAME: specify input file name, default EIGENVAL  
    -n : noncollinear format  
    -c : collinear format  
    -h : show this message  
