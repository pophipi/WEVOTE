#!/bin/bash


## parse commandline arguments
Usage="\nUsage: $0 -i <input-file> -p <output-prefix> --db <path-to-taxonomy-DB> <options>

Implemented options:
-h|--help                  \t help flag
-i|--input <input-file>    \t input query
-p|--prefix <output-prefix>  \t Output prefix
--db <taxonomy_db>         \t taxonomy database path
--threads <num-threads>    \t Number of threads
--seqcount <contig-reads-count-file>	\t File that contains how many reads are used to assemble each contig 
"


query=""
prefix=""
taxonomyDB=""
seqID_count_file=""



if [ $# -lt 2 ]; then
echo -e "$Usage"
exit
fi


while [[ $# > 0 ]]
do
key="$1"

case $key in

    -h|--help)
                echo -e "$Usage"
                ;;
    -i|--input)
                query=$2
                queryPath=`readlink -f $query | xargs dirname`
                queryName=`basename $query`
                query=$queryPath/$queryName
                prefix=`basename ${query%.*}`
                dirPath=`pwd`
                echo "Query= "$query
                shift
                ;;
    -p|--prefix)
                prefix=$2
                echo "Output prefix= "$prefix
                shift
                ;;
    --db)
                taxonomyDB=$2
                echo "Taxonomy Database located at= "$taxonomyDB
                shift
                ;;
    --threads)
                threads=$2
                shift
                echo "Num of threads= "$threads 
                ;;
    --seqcount)
                seqID_count_file=$2
                shift
                echo "Contig-reads-map file located at = "$seqID_count_file 
                ;;

    *)
                echo "Sorry " $1 " is an invalid option was received."
                echo -e "$Usage"
                exit
                ;;
esac
shift
done





#### Preprocessing the WEVOTE output for read or contigs abundance 
if [ "$seqID_count_file" == "" ] ; then
	echo "read abundance"
	awk '{ print $NF ",1" }' $query  > $prefix"_WEVOTE_taxID_count.csv"

else  
	echo "contig abundance"
	awk '{ print $1 "\t" $NF}' $query | awk -F '[_\t]' '{print $2 "\t" $NF}' | sort -k1,1 > $prefix"_WEVOTE_seqID_taxID.txt"
	join $prefix"_WEVOTE_seqID_taxID.txt"  $seqID_count_file | cut -f2,3 -d " " | sed "s/ /,/g" > $prefix"_WEVOTE_taxID_count.csv"
fi 



### Get the abundance and full taxonomy
./ABUNDANCE -i $prefix"_WEVOTE_taxID_count.csv" -p $prefix -d $taxonomyDB
