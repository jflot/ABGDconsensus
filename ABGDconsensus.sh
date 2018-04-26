#! /usr/bin/env bash
# -*- coding: UTF-8 -*-
#Copyright (c) 2017-2018, JF Flot <jflot@ulb.ac.be>
#
#Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is
#hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
#
#THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE
#INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
#USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# commandline parsing
TMPFOLDER=TMP
OUTFOLDER=OUT
HELP=false
VERBOSE=false
JC=false
K2P=false
TN=false
SD=false
FILES=()
while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
    -v)
    VERBOSE=true
    shift
    ;;
    -h)
    HELP=true
    shift
    ;;
    -JC)
    JC=true
    shift
    ;;
    -K2P)
    K2P=true
    shift
    ;;
    -TN)
    TN=true
    shift
    ;;
    -SD)
    SD=true
    shift
    ;;
    -o)
    OUTFOLDER="$2"
    shift
    shift
    ;;
    -t)
    TMPFOLDER="$2"
    shift
    shift
    ;;
    -*)
    echo "UNRECOGNIZED OPTION $key"
    HELP=true
    exit 1
    ;;
    *)
    FILES+=("$1")
    shift
    ;;
  esac
done

if [ ${#FILES[@]} -eq 0 ]
 then
 HELP=true
fi

#help
if $HELP
then
  echo "Usage: ABGDconsensus.sh [options] INPUTFILE(S)"
  echo "INPUTFILE(S) should be in FASTA format"
  echo "Options: -v = verbose"
  echo "         -h = help"
  echo "         -o = output folder (default is OUT)"
  echo "         -t = temporary work folder (default is TMP)"
  echo "         -K2P = use Kimura-2P distances"
  echo "         -JC  = use Jukes-Cantor distances"
  echo "         -TN  = use Tamura-Nei distances"
  echo "         -SD  = use simple distances (p-distances)"
  echo "         (if no distance is specified, ABGDconsensus will use all four)"
fi

if [ ${#FILES[@]} -eq 0 ]
 then
 echo "No input file provided."
 exit 1
fi


# get the path to the executable adbd ...
ABGD_EXECUTABLE=$(which abgd)
if [ "$?" != "0" ]; then
  echo "Please install ABGD and/or put it into one the folders in your PATH variable."
  exit 1
fi

# check if directory "TMP" alreadt exists in current directory
if [ -d "$TMPFOLDER" ]; then
  while true
  do
    read -p "Temporary directory already exists. Type e in order to empty this directory and q in order to quit this program. " choice
    case "$choice" in 
       e|E ) echo "Deleting content"; rm -rf TMP; break;;
       q|Q ) echo "Exiting"; exit 1;;
       * ) echo "Input invalid";;
    esac
  done
fi

# check if directory "OUT" alreadt exists in current directory
if [ -d "$OUTFOLDER" ]; then
  while true
  do
    read -p "Output temporary directory already exists. Type e in order to empty this directory and q in order to quit this program. " choice
    case "$choice" in 
       e|E ) echo "Deleting content"; rm -rf OUT; break;;
       q|Q ) echo "Exiting"; exit 1;;
       * ) echo "Input invalid";;
    esac
  done
fi


# create the OUT folder
mkdir "$OUTFOLDER"

# check if the OUT directory was created; if not, quit with an error message
if [[ ! "$OUTFOLDER" || ! -d "$OUTFOLDER" ]]; then
  echo "Could not create the temporary directory!"
  exit 1
fi


# test input files
for i in "${!FILES[@]}"
do
  filename=${FILES[$i]}
  if [ -z "$filename" ]
  then
    echo "Empty file name given!"
    exit 1
  fi
  if [ -f "$filename" ]
  then
    if [ ! -r "$filename" ]
    then
      echo "File $filename exists but I do not have reading permission."
      exit 1
    fi
  else
    echo "File $filename does not exist."
    exit 1
  fi
done


echo "Number of files to process ${#FILES[@]}"
echo ""


 # setting the method(s)
if ! $SD && ! $JC && ! $K2P && ! $TN
then SD=true; JC=true; K2P=true; TN=true
fi  

# for each fasta file, run ABGD
for i in "${!FILES[@]}"
    do
    # create the TMP folder and its subfolders
    mkdir "$TMPFOLDER"
    mkdir "$TMPFOLDER/K2P"
    mkdir "$TMPFOLDER/JC"
    mkdir "$TMPFOLDER/TN"
    mkdir "$TMPFOLDER/SD"
    # check if the TMP directory was created; if not, quit with an error message
    if [[ ! "$TMPFOLDER" || ! -d "$TMPFOLDER" ]]; then
      echo "Could not create the temporary directory!"
      exit 1
    fi

    file=${FILES[$i]}
 # running ABGD with Kimura-2P distances
if $K2P; then
    if $VERBOSE
    then
       echo ""; echo ""
       echo "Running ABGD on $file with Kimura-2P distances and X=1.5"
       $ABGD_EXECUTABLE -a -d 0 -o $TMPFOLDER/K2P $file
    else 
       $ABGD_EXECUTABLE -a -d 0 -o $TMPFOLDER/K2P $file &>$TMPFOLDER/K2P/lastABGDoutput
    fi 
    if ! ls $TMPFOLDER/K2P/*part.2.txt 1>/dev/null 2>&1
    then 
       if $VERBOSE
          then echo ""; echo ""
          echo "Running ABGD on $file with Kimura-2P distanced and X=1.0"
       fi
       $ABGD_EXECUTABLE -a -d 0 -X 1.0 -o $TMPFOLDER/K2P $file &>$TMPFOLDER/K2P/lastABGDoutput
       if $VERBOSE
          then cat $TMPFOLDER/K2P/lastABGDoutput
       fi

       if ! ls $TMPFOLDER/K2P/*part.2.txt 1>/dev/null 2>&1
       then 
          if $VERBOSE
             then
             echo ""; echo ""
             echo "Running ABGD on $file with Kimura-2P distances and X=0.5"
             $ABGD_EXECUTABLE -a -d 0 -X 0.5 -o $TMPFOLDER/K2P $file
             else 
             $ABGD_EXECUTABLE -a -d 0 -X 0.5 -o $TMPFOLDER/K2P $file &>$TMPFOLDER/K2P/lastABGDoutput
          fi
      fi
   fi
fi


    # running ABGD with Jukes-Cantor distances
if $JC; then
    if $VERBOSE
    then
       echo ""; echo ""
       echo "Running ABGD on $file with Jukes-Cantor distances and X=1.5"
       $ABGD_EXECUTABLE -a -d 1 -o $TMPFOLDER/JC $file
    else 
       $ABGD_EXECUTABLE -a -d 1 -o $TMPFOLDER/JC $file &>$TMPFOLDER/JC/lastABGDoutput
    fi 
    if ! ls $TMPFOLDER/JC/*part.2.txt 1>/dev/null 2>&1
    then 
       if $VERBOSE
          then
          echo ""; echo ""
          echo "Running ABGD on $file with Jules-Cantor distances and X=1.0"
          $ABGD_EXECUTABLE -a -d 1 -X 1.0 -o $TMPFOLDER/JC $file
          else 
          $ABGD_EXECUTABLE -a -d 1 -X 1.0 -o $TMPFOLDER/JC $file &>$TMPFOLDER/JC/lastABGDoutput
       fi
       if ! ls $TMPFOLDER/JC/*part.2.txt 1>/dev/null 2>&1
       then 
          if $VERBOSE
             then
             echo ""; echo ""
             echo "Running ABGD on $file with Jules-Cantor distances and X=0.5"
             $ABGD_EXECUTABLE -a -d 1 -X 0.5 -o $TMPFOLDER/JC $file
             else 
             $ABGD_EXECUTABLE -a -d 1 -X 0.5 -o $TMPFOLDER/JC $file &>$TMPFOLDER/JC/lastABGDoutput
          fi
      fi
   fi
fi

 # running ABGD with Tamura-Nei distances
if $TN; then
    if $VERBOSE
    then
       echo ""; echo ""
       echo "Running ABGD on $file with Tamura-Nei distances and X=1.5"
       $ABGD_EXECUTABLE -a -d 2 -o $TMPFOLDER/TN $file
    else 
       $ABGD_EXECUTABLE -a -d 2 -o $TMPFOLDER/TN $file &>$TMPFOLDER/TN/lastABGDoutput
    fi 
    if ! ls $TMPFOLDER/TN/*part.2.txt 1>/dev/null 2>&1
    then 
       if $VERBOSE
          then
          echo ""; echo ""
          echo "Running ABGD on $file with Tamura-Nei distances and X=1.0"
          $ABGD_EXECUTABLE -a -d 2 -X 1.0 -o $TMPFOLDER/TN $file
          else 
          $ABGD_EXECUTABLE -a -d 2 -X 1.0 -o $TMPFOLDER/TN $file &>$TMPFOLDER/TN/lastABGDoutput
       fi
       if ! ls $TMPFOLDER/TN/*part.2.txt 1>/dev/null 2>&1
       then 
          if $VERBOSE
             then
             echo ""; echo ""
             echo "Running ABGD on $file with Tamura-Nei distances and X=0.5"
             $ABGD_EXECUTABLE -a -d 2 -X 0.5 -o $TMPFOLDER/TN $file
             else 
             $ABGD_EXECUTABLE -a -d 2 -X 0.5 -o $TMPFOLDER/TN $file &>$TMPFOLDER/TN/lastABGDoutput
          fi
      fi
   fi
fi

    # running ABGD with simple distances
if $SD; then
    if $VERBOSE
    then
       echo ""; echo ""
       echo "Running ABGD on $file with simple distances and X=1.5"
       $ABGD_EXECUTABLE -a -d 3 -o $TMPFOLDER/SD $file
    else 
       $ABGD_EXECUTABLE -a -d 3 -o $TMPFOLDER/SD $file &>$TMPFOLDER/SD/lastABGDoutput
    fi 
    if ! ls $TMPFOLDER/SD/*part.2.txt 1>/dev/null 2>&1
    then 
       if $VERBOSE
          then
          echo ""; echo ""
          echo "Running ABGD on $file with simple distances and X=1.0"
          $ABGD_EXECUTABLE -a -d 3 -X 1.0 -o $TMPFOLDER/SD $file
          else 
          $ABGD_EXECUTABLE -a -d 3 -X 1.0 -o $TMPFOLDER/SD $file &>$TMPFOLDER/SD/lastABGDoutput
       fi
       if ! ls $TMPFOLDER/SD/*part.2.txt 1>/dev/null 2>&1
       then 
          if $VERBOSE
             then
             echo ""; echo ""
             echo "Running ABGD on $file with simple distances and X=0.5"
             $ABGD_EXECUTABLE -a -d 3 -X 0.5 -o $TMPFOLDER/SD $file
             else 
             $ABGD_EXECUTABLE -a -d 3 -X 0.5 -o $TMPFOLDER/SD $file &>$TMPFOLDER/SD/lastABGDoutput
          fi
      fi
   fi
fi


   # outputting consensus species delimitation and generating .tsv files
   echo ""; echo ""
   if  ! ls $TMPFOLDER/*/* 1>/dev/null 2>&1
   then
   echo "ABGD failed to delimit species for $file. Trying another distance metrics (such as simple distances) may solve the problem."
   else 
       echo "Consensus species delimitation for $file:"
       if ! ls $TMPFOLDER/*/*part.2.txt 1>/dev/null 2>&1
          then
          echo "All individuals are conspecific."
          grep '>' $file|sed 's/>//'| tr -d "'"| awk '{print $1"\t1"}' > $OUTFOLDER/$file.tsv

          else
          cat `md5sum $TMPFOLDER/*/*txt| awk '{print $2,$1}'| sort -k2,2| uniq -c -f1|sort -k1,1 -rn|head -1| awk '{print $2}'` > ${TMPFOLDER}/output
          cat ${TMPFOLDER}/output
          while read line; do
            number=$(echo "$line" | cut -d"[" -f 2 | cut -d"]" -f 1)
            ids=$(echo "$line" | cut -d";" -f 2)
            ids=${ids:4}
            for id in $ids
            do
              echo -e "$id\t$number" | tr -d "'" >> $OUTFOLDER/$file.tsv
            done
          done < ${TMPFOLDER}/output

   #       rm -rf ${TMPFOLDER}
          echo ""
       fi
   fi

done


