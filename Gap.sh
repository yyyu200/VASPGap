#!/bin/bash
# find the VBM from EIGENVAL
# DO NOT CHANGE ANYTHING BELOW THIS LINE
# warning : use with care: fractional valence charge (e.g. H1.25), noncollinear/ collinear judge by yourself
# dependencies: awk
# yz 2015

if [ -z $1 ]
then
    echo -e "\e[31mWARNING: use -c or -n for collinear/noncollinear results, use -h for help\e[0m"
fi

while getopts "f:nch" arg
do
	case $arg in
		f)
			file_in=`echo "$OPTARG"`;;
		n)
			flag_noncol=1;;
		c)
			flag_noncol=0;;
		h)
			echo "Find band gap for VASP from EIGENVAL"
			echo "Gap.sh [-f FILENAME -n -c -h ]"; 
			echo "    -f FILENAME: specify input file name"; 
			echo "    -n : noncollinear format";
			echo "    -c : collinear format";
			echo "    -h : show this message";
			exit 1 ;;
		?)
			echo "unkown argument";echo "use -h for help"; exit 1;;
	esac
done

if [ -z $file_in ] 
then
	file_in='EIGENVAL'
fi
if [ ! -e $file_in ]
then
	echo "cannot find $file_in"
	exit 1
fi
echo -e "Find Band Gap for Insulators and Semiconductors. \nreading $file_in ..."

if [ `wc -l $file_in|awk '{print $1}'` -eq 6 ]; then
	echo "scf not end"
	exit 1
fi

if [ `awk 'NR==1{print $4}' $file_in` -eq 2 ];then
	flag_sp=1
elif [ `awk 'NR==1{print $4}' $file_in` -eq 1 ];then
	flag_sp=0
else
	echo "unkown format: $file_in"
	exit 1
fi
echo "spin polarized(0:no- 1:yes): $flag_sp"


NKP=`awk 'NR==6{print $2}' $file_in`
echo "        number of k-points = "$NKP

NBD=`awk 'NR==6{print $3}' $file_in`
echo "           number of bands = "$NBD

VALENT=`awk 'NR==6{print $1}' $file_in`
echo "number of valent electrons = $VALENT"
if [ -z $flag_noncol ];then
	if [ $VALENT -le $NBD ];then
		flag_noncol=1
		echo -e "\e[31m WARNING: assume non-collinear for band number > valent\n(Please Know What You Are Doing. for collinear calculation, add -c)\e[0m"
	elif [ $VALENT -gt $NBD ];then
		flag_noncol=0
        echo "collinear calculation"
	#else
	#	flag_noncol=0
	#	echo -e "\033[31m WARNING: assume collinear for band number < valent \n(Please Know What You Are Doing. for non-collinear calculation, add -n)\033[0m"
	fi
fi
echo "noncollinear(0:no- 1:yes): $flag_noncol"

if [ $flag_noncol -eq 0 ];then
	VALENT=`echo "$VALENT / 2 "|bc`
#	echo "half electron"
fi

if [ $VALENT -gt $NBD ];then
	echo "unkown format:nelectron > nbands:$VALENT $NBD"
	exit 1
fi

if [ $flag_sp -eq 0 ];then
	vbm=-9999
	cbm=9999
	kvbm=-1
	kcbm=-1
	for (( c=1; c <= $NKP; c++ ))
	do
	tmpstr=`awk 'NR==(('"$c"'-1)*(2+'"$NBD"')+8+'"$VALENT"') {printf("%d %f ",$1,$2);getline;printf(" %d %f\n",$1,$2)}' $file_in`
	vb=`echo $tmpstr|awk '{print $2}'`
	cb=`echo $tmpstr|awk '{print $4}'`
	ivb=`echo $tmpstr|awk '{print $1}'`
	icb=`echo $tmpstr|awk '{print $3}'`
	if [ `echo "$vbm < $vb"|bc` -eq 1 ]
	then
		vbm=$vb
		kvbm=$c
	fi
	if [ `echo "$cbm > $cb"|bc` -eq 1 ]
	then
		cbm=$cb
		kcbm=$c
	fi
	done
    
    if [ $kvbm -eq $kcbm ]
    then
        echo "found direct band gap"
    else
        echo "found indirect band gap"
    fi 
	echo -e "                     VB CB = $ivb $icb"
	echo -e "                E(VBM CBM) = $vbm $cbm (eV)"
	echo -e "                 kvbm kcbm = $kvbm $kcbm"
	echo -e "                  band gap =\e[01;31m `awk 'BEGIN{print '"$cbm"'-('"$vbm"')}'`\e[0m"

elif [ $flag_sp -eq 1 ]
then
	vbm_u=-9999
	vbm_d=-9999
	cbm_u=9999
	cbm_d=9999
	kvbm_u=-1
	kvbm_d=-1
	kcbm_u=-1
	kcbm_d=-1
	for (( c=1; c <= $NKP; c++ ))
	do
	tmpstr=`awk 'NR==(('"$c"'-1)*(2+'"$NBD"')+8+'"$VALENT"') {printf("%d %f %f ",$1,$2,$3);getline;printf(" %d %f %f\n",$1,$2,$3);}' $file_in`
	vb_u=`echo $tmpstr|awk '{print $2}'`
	vb_d=`echo $tmpstr|awk '{print $3}'`
	cb_u=`echo $tmpstr|awk '{print $5}'`
	cb_d=`echo $tmpstr|awk '{print $6}'`
	ivb=`echo $tmpstr|awk '{print $1}'`
	icb=`echo $tmpstr|awk '{print $4}'`
	if [ `echo "$vbm_u < $vb_u"|bc` -eq 1 ]
	then
		vbm_u=$vb_u
		kvbm_u=$c
	fi
	if [ `echo "$vbm_d < $vb_d"|bc` -eq 1 ]
	then
		vbm_d=$vb_d
		kvbm_d=$c
	fi
	if [ `echo "$cbm_u > $cb_u"|bc` -eq 1 ]
	then
		cbm_u=$cb_u
		kcbm_u=$c
	fi
	if [ `echo "$cbm_d > $cb_d"|bc` -eq 1 ]
	then
		cbm_d=$cb_d
		kcbm_d=$c
	fi
	done
	
	echo "gap between $ivb $icb (Please Know What You Are Doing.)"
	echo "VBM CBM (up) = $vbm_u $cbm_u"
	echo "kvbm kcbm (up) = $kvbm_u $kcbm_u"
	echo "band gap (up) = `awk 'BEGIN{print '"$cbm_u"'-('"$vbm_u"')}'`"
	echo "VBM CBM (down) = $vbm_d $cbm_d"
	echo "kvbm kcbm (down) = $kvbm_d $kcbm_d"
	echo "band gap (down) = `awk 'BEGIN{print '"$cbm_d"'-('"$vbm_d"')}'`"

fi

echo -en "\e[0m"
