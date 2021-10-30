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
STYLEMINAMOUNT=3 # min amount of complex style images per style transfer
STYLEMAXAMOUNT=3 # max amount of complex style images per style transfer

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
            # Append unique complex style(s)
            RANDOMCOMPLEXSTYLE=$(find $STYLEDIR/complex -type f | shuf -n 1 | tr '\n' ' ')
            while [[ "${STYLEARRAY[*]}" =~ "${RANDOMCOMPLEXSTYLE}" ]];do
              RANDOMCOMPLEXSTYLE=$(find $STYLEDIR/complex -type f | shuf -n 1 | tr '\n' ' ')
            done
            STYLELIST=${STYLELIST}${RANDOMCOMPLEXSTYLE}
            STYLEARRAY[${#STYLEARRAY[@]}]=$RANDOMCOMPLEXSTYLE
        done

        # Append random simple style
        RANDOMSIMPLESTYLE=$(find $STYLEDIR/simple -type f | shuf -n 1 | tr '\n' ' ')
        STYLELIST=${STYLELIST}${RANDOMSIMPLESTYLE}
        JSONINPUT=$(echo $STYLELIST | awk '{for(i=1;i<NF;i++)if(i!=NF){$i=$i","}  }1' | awk '{$1=$1};1')
        
        # Create random ID
        RANDOMID=$(shuf -i1-10000 -n1)

# Output result to logfile
cat <<EOF >> $OUTPUTFILE
{"name": "${RANDOMID}-$file", "styles": "[$JSONINPUT]"},
EOF

        # Run the style transfer with a randomized amount of styles
        style_transfer $CONTENTDIR/$file $STYLELIST -o $RESULTDIR/${RANDOMID}-${file} -s $IMAGESIZE
        
        # Optionally remove content file
        if [ "$REMOVE" == 'yes' ]
        then
            rm $CONTENTDIR/$file
        fi
    done
done


