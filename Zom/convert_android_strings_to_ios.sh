#!/bin/bash

if [ "$#" != "2" ]; then
    echo "Usage: $0 <storyboardfile> <android-base-strings-file>"
    echo "example: $0 ./OTRResources/Interface/Base.lproj/Onboarding.storyboard ../../Zom-Android/app/src/main/res/values/zomstrings.xml"

    exit 1
fi

if [ ! -f $1 ]; then
    echo "storyboard file not found!"
    exit 1
fi

if [ ! -f $2 ]; then
    echo "Android base strings file not found!"
    exit 1
fi

# Check for languages
#
languages=()
ios_files=()
languages_index=0
base_file_ios="$1"
base_dir_ios="${1%%/Base.lproj*}"
for languageDir in $(find $base_dir_ios -depth 1 -name "*.lproj" -print)
do
    languageDir="${languageDir%%.lproj}" # strip .lproj
    languageDir="${languageDir##*/}" # strip everything to the last path character.lproj
    if [[ "$languageDir" == "Base" ]]
    then
	continue
    fi

    # Does the file exist for this language?
    languageFile="${base_file_ios/Base.lproj/${languageDir}.lproj}"
    languageFile="${languageFile/.storyboard/.strings}"
    if [ ! -f $languageFile ]; then
	echo "Storyboard strings file not found for language $languageDir"
	continue
    fi
    languages[languages_index]="$languageDir"
    ios_files[languages_index]="$languageFile"
    ((languages_index++))
done

# Make sure corresponding Android file exists
#
languages_index=0
while [ "x${languages[languages_index]}" != "x" ]
do
    language="${languages[languages_index]}"
    ((languages_index++))
    android_path="${2/values/values-$language}"
    if [ ! -f $android_path ]; then
	echo "Warning: no matching strings file found at: $android_path!"
    fi
done

# Extract strings from storyboard and convert to utf-8
#
ibtool --export-strings-file /tmp/storyboard.strings $1 >/dev/null || { 
    echo "Error extracting strings from $1!"
    exit 1 
} 
iconv -f utf-16 -t utf-8 /tmp/storyboard.strings >/tmp/storyboard.strings.utf8 || {
    echo "Failed to convert to utf-8"
    exit 1
}
default_strings_file="/tmp/storyboard.strings.utf8"
android_base_strings_file=$2

base_keys=()
base_translations=()
android_base_keys=()

android_keys=()
android_values=()

ios_keys=()
ios_values=()

function addBaseMapping {
    count=0
    while [ "x${base_keys[count]}" != "x" ]
    do
	((count++))
    done
    base_keys[count]="$1"
    base_translations[count]="$2"
}

function addAndroidMapping {
    count=0
    while [ "x${android_keys[count]}" != "x" ]
    do
	((count++))
    done
    android_keys[count]="$1"
    android_values[count]="$2"
}

function addiOSMapping {
    count=0
    while [ "x${ios_keys[count]}" != "x" ]
    do
	((count++))
    done
    ios_keys[count]="$1"
    ios_values[count]="$2"
}

function parseAndroidStringsFile {
    local filePath=$1
    android_keys=()
    android_values=()
    while read line ; do
	key=$(echo $line | cut -d \  -f 1)
	val=$(echo $line | cut -d \  -f 2-)
	addAndroidMapping "$key" "$val"
    done < <(awk -F'name="|">|</' '{ print $2,$3}' "$filePath")
}

function parseiOSStringsFile {
    local filePath=$1
    ios_keys=()
    ios_values=()
    while read line ; do
	key=$(echo $line | cut -d \  -f 1)
	val=$(echo $line | cut -d \  -f 2-)
	addiOSMapping "$key" "$val"
    done < <(awk -F'\ =\ |"' '{ if (NF==6) print $2,$5 }' "$filePath")
}

function findAndroidTranslation {
    local id="$1"
    local count=0
    while [ "x${android_keys[count]}" != "x" ]
    do
	thisid="${android_keys[count]}"
	if [ "$thisid" == "$id" ]; then
	    echo "${android_values[count]}"
	fi
	((count++))
    done
}

function findAndroidId {
    local id="$1"
    local count=0
    while [ "x${base_keys[count]}" != "x" ]
    do
	thisid="${base_keys[count]}"
	if [ "$thisid" == "$id" ]; then
	    echo "${android_base_keys[count]}"
	fi
	((count++))
    done
}

while read line ; do
    key=$(echo $line | cut -d \  -f 1)
    val=$(echo $line | cut -d \  -f 2-)
    addBaseMapping "$key" "$val"
done < <(awk -F'\ =\ |"' '{ if (NF==6) print $2,$5 }' $default_strings_file)

parseAndroidStringsFile "$android_base_strings_file"

# Try to find all translations and their corresponding ids
#
i_translation=0
while [ "x${base_translations[i_translation]}" != "x" ]
do
    term="${base_translations[i_translation]}"
    
    id=""
    count=0
    while [ "x${android_values[count]}" != "x" ] 
    do
	if [ "${android_values[count]}" == "$term" ]; then
	    id="${android_keys[count]}"
	fi
	((count++))
    done
    
    if [ "$id" == "" ]; then
	echo "Could not find Android string id for $term"
	#exit 1
	android_base_keys[i_translation]=""
    else
	#echo "Lookup for $term is $id"
	android_base_keys[i_translation]="$id"
    fi
    ((i_translation++))
done


# Get Android language file
#
languages_index=0
while [ "x${languages[languages_index]}" != "x" ]
do
    language="${languages[languages_index]}"
    ios_file="${ios_files[languages_index]}"
    echo "Processing language: $language"
    ((languages_index++))
    android_file="${android_base_strings_file/values/values-$language}"
    if [ -f $android_file ]; then

	# Copy a fresh strings file to our target ios language file
	cp /tmp/storyboard.strings.utf8 "$ios_file"

	parseAndroidStringsFile "$android_file"
	parseiOSStringsFile "$ios_file"
	
	# Apply translation to all ios values
        # First pass: update ios_values with translated strings
	count=0
	while [ "x${ios_keys[count]}" != "x" ]
	do
	    key="${ios_keys[count]}"
	    # Get android id of key
	    android_key=$(findAndroidId "$key")
	    if [ "$android_key" != "" ]; then
		translation=$(findAndroidTranslation "$android_key")
		if [ "$translation" == "" ]; then
		    echo "Language $language: missing translation for id $android_key."
		else
		    ios_values[count]="$translation"
		fi
	    fi
	    ((count++))
	done

        # Second pass: update the actual file
	count=0
	while [ "x${ios_keys[count]}" != "x" ]
	do
	    key="${ios_keys[count]}"
	    value="${ios_values[count]}"
	    value="${value//\&/\\&}"
	    echo "Update file $ios_file with $key -> $value"
	    sed -e "s/$key\" =.*/$key\" = \"$value\";/" -i "" "$ios_file"
	    ((count++))
	done
    fi
done

