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
STYLEMINAMOUNT=3 # min amount of style images per style transfer
STYLEMAXAMOUNT=3 # max amount of style images per style transfer
IMAGESIZE=512 # max image size in px

## Install the packages
pip install -e .
apt update -y && apt install zip -y
pip install --upgrade --force-reinstall pillow

#loop X times
for iteration in $(seq 1 $LOOPS)
do
    ## Run the model for each contentfile
    for file in `ls $CONTENTDIR`
    do
        # Remove notebook checkpoint folders
        find $STYLEDIR -type d -name '.ipynb_checkpoints' -exec rm -rf {} +

        # Get n random style files
        RANDOMNUMBER=$(shuf -i$STYLEMINAMOUNT-$STYLEMAXAMOUNT -n1)

        STYLELIST=""
        STYLEARRAY=()

        # Loop through directory n times
        for i in $(seq 1 $RANDOMNUMBER)
        do
            # Select random rarity folder
            RANDOMFOLDER=$(shuf -i1-100 -n1)
            if [ $RANDOMFOLDER -lt 50 ]; then
                RARITYFOLDER=common
            elif [ $RANDOMFOLDER -lt 85 ] ; then
                RARITYFOLDER=uncommon
            elif [ $RANDOMFOLDER -lt 95 ] ; then
                RARITYFOLDER=rare
            elif [ $RANDOMFOLDER -lt 100 ] ; then
                RARITYFOLDER=superrare
            else
                RARITYFOLDER=ultrarare
            fi

            RANDOMSTYLEFILE=$(find $STYLEDIR/$RARITYFOLDER -type f | shuf -n 1 | tr '\n' ' ')
            while [[ "${STYLEARRAY[*]}" =~ "${RANDOMSTYLEFILE}" ]];do
            RANDOMSTYLEFILE=$(find $STYLEDIR/$RARITYFOLDER -type f | shuf -n 1 | tr '\n' ' ')
            done
            STYLELIST=${STYLELIST}${RANDOMSTYLEFILE}
            STYLEARRAY[${#STYLEARRAY[@]}]=$RANDOMSTYLEFILE
        done

        JSONINPUT=$(echo "$STYLELIST" | awk '{for(i=1;i<NF;i++)if(i!=NF){$i=$i","}  }1' | awk '{$1=$1};1')
        
# Output result to logfile
cat <<EOF >> $OUTPUTFILE
{"name": "$file", "styles": "[$JSONINPUT]", "style_amount": "$RANDOMNUMBER"},
EOF

        # Run the style transfer with a randomized amount of styles
        style_transfer $CONTENTDIR/$file $STYLELIST -o $RESULTDIR/$file -s $IMAGESIZE
        
        # Optionally remove content file
        if [ "$REMOVE" == 'yes' ]
        then
            rm $CONTENTDIR/$file
        fi

    done
done
