#!/bin/bash
# applies style-transfer to existing content image in a loop using style images

read -p 'Where to store results? ' RESULTDIR
read -p 'Repeat process how many times?' LOOPS

# Directory & File variables
CONTENTDIR=content # directory where content is stored
STYLEDIR=styles # directory where styles are stored
WORKDIR=.
CONTENTEXTENSION=jpg

OUTPUTFILE=output.log

# Processing Variables
STYLEMINAMOUNT=2 # min amount of style images per style transfer
STYLEMAXAMOUNT=3 # max amount of style images per style transfer
IMAGESIZE=512 # max image size in px

## Install the packages
pip install -e $WORKDIR
apt update -y && apt install zip -y

## Run the model for each contentfile
for i in $(seq 1 $LOOPS)
do
    # Remove notebook checkpoint folder
    rm -rf $STYLEDIR/.ipynb_checkpoints
    # Get n random style files
    RANDOMNUMBER=$(shuf -i$STYLEMINAMOUNT-$STYLEMAXAMOUNT -n1)
    RANDOMSTYLEFILE=$(find $STYLEDIR -type f | shuf -n $RANDOMNUMBER | tr '\n' ' ')
    JSONINPUT=$(echo "$RANDOMSTYLEFILE" | awk '{for(i=1;i<NF;i++)if(i!=NF){$i=$i","}  }1' | awk '{$1=$1};1')
    # Run the style transfer with a randomized amount of styles
    style_transfer $CONTENTDIR/${i}.$jpg $RANDOMSTYLEFILE -o $RESULTDIR/${i}.png -s $IMAGESIZE
    if [[ ${#i} -eq 1 ]]
        then
            NAME="000$i"
    elif [[ ${#i} -eq 2 ]]
        then
            NAME=="00$i"
    elif [[ ${#i} -eq 3 ]]
        then
            NAME=="0$i"
    else
        NAME=="$i"
    fi
    
# Output result to logfile
cat <<EOF >> $OUTPUTFILE
{"name": "$NAME", "styles": "[$JSONINPUT]", "style_amount": "$RANDOMNUMBER"},
EOF
done
