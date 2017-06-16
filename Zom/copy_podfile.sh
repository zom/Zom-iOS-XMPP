#!/bin/bash
# Copies ChatSecure's Podfile and applies Zom-specific modifications

# Get directory containing `copy_podfile.sh` 
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Copy Podfile from ChatSecure to Zom
cp $DIR/../ChatSecure/Podfile $DIR/Podfile

# Replace some paths and target-specific stuff
perl -pi -e 's/ChatSecureCore/Zom/g' $DIR/Podfile
perl -pi -e 's/Submodules/..\/ChatSecure\/Submodules/g' $DIR/Podfile
perl -pi -e 's/Podspecs/..\/ChatSecure\/Podspecs/g' $DIR/Podfile
perl -pi -e "s/target 'Chat/#target 'Chat/g" $DIR/Podfile

# Inject the Zom unique pods here
mv $DIR/Podfile $DIR/Podfile.temp
while IFS= read -r line
do
    if [[ "$line" =~ ^.*target."'Zom".*$ ]]
    then
	echo -n "  "
        cat $DIR/Podfile.Zom
	echo ""
    fi
    echo "$line"
done <$DIR/Podfile.temp >$DIR/Podfile
rm $DIR/Podfile.temp

echo "Updated Zom/Podfile from upstream ChatSecure"

# Copy Cartfile from ChatSecure to Zom
cp $DIR/../ChatSecure/Cartfile $DIR/Cartfile
echo "Updated Zom/Cartfile from upstream ChatSecure"
