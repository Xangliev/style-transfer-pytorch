#!/bin/bash
# applies style-transfer to faces using existing faces & style images

# Directory & File variables
CONTENTDIR=./content # directory where content is stored
STYLEDIR=./styles # directory where styles are stored
RESULTDIR=/storage # directory to save result to (for testing you can change it to '.')
WORKDIR=.

OUTPUTFILE=./output.log

# Processing Variables
STYLEAMOUNT=3 # max amount of style images per style transfer
IMAGESIZE=480 # max image size in px

## Install the packages
pip install -e $WORKDIR
apt update -y && apt install zip -y

## Run the model for each contentfile
for file in `ls $CONTENTDIR`
do
    # Get n random style files
    RANDOMNUMBER=$(shuf -i1-$STYLEAMOUNT -n1)
    RANDOMSTYLEFILE=$(find $STYLEDIR -type f | shuf -n $RANDOMNUMBER | tr '\n' ' ')
    JSONINPUT=$(echo "$RANDOMSTYLEFILE" | awk '{for(i=1;i<NF;i++)if(i!=NF){$i=$i","}  }1' | awk '{$1=$1};1')
    # Run the style transfer with a randomized amount of styles
    style_transfer $CONTENTDIR/$file $RANDOMSTYLEFILE -o $RESULTDIR/$file -s $IMAGESIZE

# Output result to logfile
cat <<EOF >> $OUTPUTFILE
{"name": "$file", "styles": "[$JSONINPUT]", "style_amount": "$RANDOMNUMBER"},
EOF
done
