#!/bin/bash

#######
# A Script to sync strings between Android and iOS projects, or rather: use Android strings in iOS storyboards
# Created 2016 by N-Pex
#
# The process is the following:
#
# Step 1 - Search through all lproj directories, finding all localized strings files matching the given storyboard.
# Step 2 - Make sure corresponding Android strings file exists.
# Step 3 - Extract strings from base storyboard and convert to utf-8. Split them into key-value pairs.
# Step 4 - Extract strings from base android strings file, split into key-value pairs.
# Step 5 - Match translated strings iOS<->Android. If they match, store the id mapping between them.
# Step 6 - Go through the iOS strings files, get the corresponding Android strings file and use the id mapping built in Step 5 to update the strings.

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


# Helper to translate from iOS language codes into corresponding Android language codes
ios_language_codes=("Base" "en" "da-DK" "fa-IR" "nb-NO" "nl-NL" "pt-BR" "pt-PT" "ro-RO" "sl-SI" "zh-Hans-CN" "zh-Hant-TW")
android_language_codes=("" "" "-da" "-fa" "-nb" "-nl" "-pt-rBR" "-pt" "-ro" "-sl-rSI" "-zh-rCN" "-zh-rTW")

function getAndroidLanguageCodeFromiOSLanguageCode {
    local id="$1"
    local count=0
    while [ "x${ios_language_codes[count]}" != "x" ]
    do
	thisid="${ios_language_codes[count]}"
	if [ "$thisid" == "$id" ]; then
	    echo "${android_language_codes[count]}"
	    return 1
	fi
	((count++))
    done
    echo "-$id"
}

# Step 1 - Search through all lproj directories, finding all localized strings files matching the given storyboard.
#
#
languages=()
ios_files=()
languages_index=0
base_file_ios="$1"
base_dir_ios="${1%%/Base.lproj*}"
echo "Basr dir is $base_dir_ios"
for languageDir in $(find $base_dir_ios -depth 1 -name "*.lproj" -print)
do
    languageDir="${languageDir%%.lproj}" # strip .lproj
    languageDir="${languageDir##*/}" # strip everything to the last path character.lproj
    #if [[ "$languageDir" == "Base" ]]
    #then
#	continue
#    fi

    echo "$LanguageFile"

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

# Step 2 - Make sure corresponding Android strings file exists
#
#
languages_index=0
while [ "x${languages[languages_index]}" != "x" ]
do
    language="${languages[languages_index]}"
    language=$(getAndroidLanguageCodeFromiOSLanguageCode "$language")
    ((languages_index++))
    android_path="${2/values/values$language}"
    if [ ! -f $android_path ]; then
	echo "Warning: no matching strings file found at: $android_path!"
    fi
done

# Step 3 - Extract strings from base storyboard and convert to utf-8. Split them into key-value pairs.
#
#
ibtool --export-strings-file /tmp/Localizable.strings "$1"
iconv -f utf-16 -t utf-8 /tmp/Localizable.strings >/tmp/Localizable.strings.utf8 || {
    echo "Failed to convert to utf-8"
    exit 1
}
default_strings_file="/tmp/Localizable.strings.utf8"
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
    while read -r line ; do
	key=$(echo $line | cut -d \  -f 1)
	val=$(echo $line | cut -d \  -f 2-)
	addAndroidMapping "$key" "$val"
    done < <(awk -F'name="|">|</' '{ print $2,$3}' "$filePath")
}

function parseiOSStringsFile {
    local filePath="$1"
    echo "Parsing iOS file $filePath"
    ios_keys=()
    ios_values=()
    while read -r line || [[ -n $line ]]; do
	sep=" = "
	case $line in
	    (*"$sep"*)
	    key=${line%%"$sep"*}
	    value=${line#*"$sep"}
	    ;;
	    (*)
	    key=
	    value=
	    ;;
	esac
	if [ "$key" != "" ]; then
	    # Cleanup key and value by removing quotes
	    key=${key#\"}
	    key=${key%\"}
	    value=${value#\"}
	    value=${value%\";}
	    echo "Adding mapping $key --> $value"
	    addiOSMapping "$key" "$value"
	fi
    done < <(sed -n '/^\".*;$/p' "$filePath")
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

while read -r line || [[ -n $line ]]; do
    sep=" = "
    case $line in
	(*"$sep"*)
	key=${line%%"$sep"*}
	value=${line#*"$sep"}
	;;
	(*)
	key=
	value=
	;;
    esac
    if [ "$key" != "" ]; then
	    # Cleanup key and value by removing quotes
	key=${key#\"}
	key=${key%\"}
	value=${value#\"}
	value=${value%\";}
	echo "Adding base mapping $key --> $value"
	addBaseMapping "$key" "$value"
    fi
done < <(sed -n '/^\".*;$/p' "$default_strings_file")







# Step 4 - Extract strings from base android strings file, split into key-value pairs.
#
#
parseAndroidStringsFile "$android_base_strings_file"

# Step 5 - Match translated strings iOS<->Android. If they match, store the id mapping between them.
#
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


# Step 6 - Go through the iOS strings files, get the corresponding Android strings file and use the id mapping built in Step 5 to update the strings.
#
#
languages_index=0
while [ "x${languages[languages_index]}" != "x" ]
do
    language="${languages[languages_index]}"
    ios_file="${ios_files[languages_index]}"
    echo "Processing language: $language ios_file $ios_file"
    ((languages_index++))
    language_suffix=$(getAndroidLanguageCodeFromiOSLanguageCode "$language")
    android_file="${android_base_strings_file/values/values$language_suffix}"
    if [ -f $android_file ]; then

	# Copy a fresh strings file to our target ios language file
	# cp /tmp/Localizable.strings.utf8 "$ios_file"

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
	    value="${value/\\/\\\\}"
	    command="s/$key\" =.*/$key\" = \"$value\";/"
	    sed -e "$command" -i "" "$ios_file"
	    ((count++))
	done

	if [ "$language" == "Base" ]; then
	    mv "$ios_file" "$ios_file.utf8"
	    iconv -f utf-8 -t utf-16 "$ios_file.utf8" > "$ios_file"
	    rm "$ios_file.utf8"
	fi
    fi
done
