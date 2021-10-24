#!/bin/bash
# applies style-transfer to existing content images using style images

read -p 'Where to store results? ' RESULTDIR
read -p 'How many loops? (default: 1) ' LOOPS
read -p 'Remove content files after processing? (yes/no default: no) ' REMOVE

# Directory & File variables
CONTENTDIR=content # directory where content is stored
STYLEDIR=styles # directory where styles are stored

OUTPUTFILE=output.log

# Processing Variables
IMAGESIZE=480 # max image size in px

## Install the packages
pip install -e .
apt update -y && apt install zip -y

#loop X times
for iteration in $(seq 1 $LOOPS)
do
    ## Run the model for each contentfile
    for file in `ls $CONTENTDIR`
    do
        # Remove notebook checkpoint folders
        find $STYLEDIR -type d -name '.ipynb_checkpoints' -exec rm -rf {} +

        STYLELIST=""

        # Select random simple rarity folder
        RANDOMSIMPLE=$(shuf -i1-100 -n1)
        if [ $RANDOMSIMPLE -lt 50 ]; then
            SIMPLEFOLDER=common
        elif [ $RANDOMSIMPLE -lt 85 ] ; then
            SIMPLEFOLDER=uncommon
        elif [ $RANDOMSIMPLE -lt 95 ] ; then
            SIMPLEFOLDER=rare
        elif [ $RANDOMSIMPLE -lt 100 ] ; then
            SIMPLEFOLDER=superrare
        else
            SIMPLEFOLDER=ultrarare
        fi

        # Select random complex rarity folder
        RANDOMCOMPLEX=$(shuf -i1-100 -n1)
        if [ $RANDOMCOMPLEX -lt 50 ]; then
            COMPLEXFOLDER=common
        elif [ $RANDOMCOMPLEX -lt 85 ] ; then
            COMPLEXFOLDER=uncommon
        elif [ $RANDOMCOMPLEX -lt 95 ] ; then
            COMPLEXFOLDER=rare
        elif [ $RANDOMCOMPLEX -lt 100 ] ; then
            COMPLEXFOLDER=superrare
        else
            COMPLEXFOLDER=ultrarare
        fi

        RANDOMSIMPLESTYLE=$(find $STYLEDIR/simple/$SIMPLEFOLDER -type f | shuf -n 1 | tr '\n' ' ')
        RANDOMCOMPLEXSTYLE=$(find $STYLEDIR/complex/$COMPLEXFOLDER -type f | shuf -n 1 | tr '\n' ' ')
        STYLELIST=${RANDOMSIMPLESTYLE}${RANDOMCOMPLEXSTYLE}

        JSONINPUT=$(echo $STYLELIST | awk '{for(i=1;i<NF;i++)if(i!=NF){$i=$i","}  }1' | awk '{$1=$1};1')
    
# Output result to logfile
cat <<EOF >> $OUTPUTFILE
{"name": "${RANDOMSIMPLE}-${RANDOMCOMPLEX}-$file", "styles": "[$JSONINPUT]"},
EOF

        # Run the style transfer with a randomized amount of styles
        style_transfer $CONTENTDIR/$file $STYLELIST -o $RESULTDIR/${RANDOMSIMPLE}-${RANDOMCOMPLEX}-${file} -s $IMAGESIZE
        
        # Optionally remove content file
        if [ "$REMOVE" == 'yes' ]
        then
            rm $CONTENTDIR/$file
        fi
    done
done
