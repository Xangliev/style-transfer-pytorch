#!/bin/bash
# applies style-transfer to existing content images using style images

# variables
CONTENTDIR=content # directory where content is stored
STYLEDIR=styles # directory where styles are stored
WORKDIR=. # working directory
OUTPUTFILE=output.log # log file

read -p "Where to store results? (hint: use '.' to store locally) " RESULTDIR

if [ ! -d $RESULTDIR ]
then
    echo "Error: directory '$RESULTDIR' does not exist."
    echo "Exiting.."
    exit 1
elif [ ! -d $CONTENTDIR ] || [ ! -d $STYLEDIR ]
then
    echo "Error: content directory '$CONTENTDIR' and/or styles directory '$STYLEDIR' do not exist."
    echo "Exiting.."
    exit 1
fi

read -p "Set minimum amount of style images for style-transfer: (recommended: 1) " STYLEMINAMOUNT
read -p "Set maximum amount of style images for style-transfer: (recommended: 3) " STYLEMAXAMOUNT
read -p "Set image size in px: (recommended: 480) " IMAGESIZE

## Install the packages
echo "Preparing the environment.."
pip install -e $WORKDIR
apt update -y && apt install zip -y

## Run the model for each file in the content directory
for file in `ls $CONTENTDIR`
do
    # Get n random style files
    RANDOMNUMBER=$(shuf -i$STYLEMINAMOUNT-$STYLEMAXAMOUNT -n1)
    RANDOMSTYLEFILE=$(find $STYLEDIR -type f | shuf -n $RANDOMNUMBER | tr '\n' ' ')
    JSONINPUT=$(echo "$RANDOMSTYLEFILE" | awk '{for(i=1;i<NF;i++)if(i!=NF){$i=$i","}  }1' | awk '{$1=$1};1')
    # Run the style transfer with a randomized amount of styles
    style_transfer $CONTENTDIR/$file $RANDOMSTYLEFILE -o $RESULTDIR/$file -s $IMAGESIZE

# Output result to logfile
cat <<EOF >> $OUTPUTFILE
{"name": "$file", "styles": "[$JSONINPUT]", "style_amount": "$RANDOMNUMBER"},
EOF
done
