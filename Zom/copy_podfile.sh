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


echo "Updated Zom/Podfile from upstream ChatSecure"