#!/bin/bash

#######
# A Script to use Android strings in iOS projects
# Created 2017 by N-Pex
#
# The process is the following:
#
# - Export an XLIFF for the base language
# - Find out what languages we have (by enumerating all *.lproj directories)
# - Export an XLIFF for each language found
# - Parse iOS base file to get iOS id <-> English string mapping
# - Parse Android base file(s) to get Android id <-> English string mapping
# - For each language:
#     parse iOS file
#     parse corresponding Android file(s)
#     use above mapping to update strings in the language xliff file
#     import the updated xliff back into the ios project
#
#
#
# This script requires xidel, found at http://videlibri.sourceforge.net/xidel.html
#
project_dir=""
project_file=""
android_input_files=()
xidel=""

function addAndroidInputFile {
    local count=0
    while [ "x${android_input_files[count]}" != "x" ]
    do
	((count++))
    done
    android_input_files[count]="$1"
}

function showUsageAndExit {
    echo "Usage: $0 -x <path_to_xidel_binary> -p <project_file> -i <android_strings_file> [-i <android_strings_file>...]";
    echo
    echo "example: $0 -p ../Zom.xcodeproj -i ../../../Zom-Android/app/src/main/res/values/zomstrings.xml -i ../../../Zom-Android/app/src/main/res/values/strings.xml"
    echo
    echo "Xidel can be found here: http://videlibri.sourceforge.net/xidel.html"
    exit
}


# Parse indata
#
while [[ $# > 0 ]]
do
    key="$1"
    case $key in
	-h|--help)
	    showUsageAndExit
	    ;;
	-x|--xidel)
	    xidel="$2"
	    shift
	    ;;
	-d|--dir)
	    project_dir="$2"
	    shift
	    ;;
	-p|--project)
	    project_file="$2"
	    shift # past argument
	    ;;
	-i|--input)
	    addAndroidInputFile "$2"
	    shift # past argument
	    ;;
    esac
    shift # past argument or value
done

echo
echo "Checking indata..."
echo

# Check that the xidel tool exists
if [ ! -f "$xidel" ]; then
    echo "xidel tool not found!"
    echo
    showUsageAndExit
fi
echo "Using xidel from $xidel"

# Check that project dir exists
if [ ! -d "$project_dir" ]; then
    echo "project dir not found!"
    echo
    showUsageAndExit
fi
echo "Project dir $project_dir found"

# Check that project file exists
if [ ! -d "$project_file" ]; then
    echo "project file not found!"
    echo
    showUsageAndExit
fi
echo "Project file $project_file found"

# Check Android input files
android_count=0
while [ "x${android_input_files[android_count]}" != "x" ]
do
    thisfile="${android_input_files[android_count]}"
    if [ ! -f "$thisfile" ]; then
	echo "Input file $thisfile not found!"
	echo
	showUsageAndExit
    fi
    echo "Android input file $thisfile found"
    ((android_count++))
done

echo
echo "Indata ok"
echo

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

# Export XLIFF files for Base
#
#
echo "Export base XLIFF file"
if [ -d "/tmp/ZomTranslations" ]; then
    rm -rf "/tmp/ZomTranslations"
fi
xcodebuild -exportLocalizations -localizationPath /tmp/ZomTranslations -exportLanguage Base -project "$project_file"

# Export for all others
#
#
languages=()
ios_files=()
languages_index=0
base_dir_ios="$project_dir/"
echo "Base dir is $base_dir_ios"
for languageDir in $(find $base_dir_ios -depth 1 -name "*.lproj" -print)
do
    language="${languageDir%%.lproj}" # strip .lproj
    language="${language##*/}" # strip everything to the last path character.lproj
    if [[ "$language" == "Base" ]]
    then
	continue
    fi
    languages[languages_index]="$language"
    ((languages_index++))
    echo "Export XLIFF for $language"
    xcodebuild -exportLocalizations -localizationPath /tmp/ZomTranslations -exportLanguage "$language" -project "$project_file"
    perl -i~ -0777 -pe "s/<file original=\"[^\.]+\.plist\"(.|\n)*?<\/file>\s*//g" "/tmp/ZomTranslations/${language}.xliff"
done

# Make sure corresponding Android strings file exists
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

# Extract ids and English translations from Base.xliff
#
#
base_keys=()
base_translations=()
android_base_keys=()

android_keys=()
android_values=()

ios_keys=()
ios_values=()


function addBaseMapping {
    local count=0
    while [ "x${base_keys[count]}" != "x" ]
    do
	((count++))
    done
    base_keys[count]="$1"
    base_translations[count]="$2"
}

function addAndroidMapping {
    local count=0
    while [ "x${android_keys[count]}" != "x" ]
    do
	((count++))
    done
    android_keys[count]="$1"
    android_values[count]="$2"
}

function addiOSMapping {
    local count=0
    while [ "x${ios_keys[count]}" != "x" ]
    do
	((count++))
    done
    ios_ids[count]="$1"
    ios_keys[count]="$2"
    ios_values[count]="$3"
}

function parseAndroidStringsFile {
    local filePath=$1
    while read -r line ; do
	key=$(echo $line | cut -d \  -f 1)
	val=$(echo $line | cut -d \  -f 2-)
        # Replace slash ' with '	
	replace=\'
        val="${val//\\\'/$replace}"
	#echo "Add mapping $key <--> $val"
	addAndroidMapping "$key" "$val"
    done < <(awk -F'name="|">|</' '{ if (NF == 4) print $2,$3}' "$filePath")
}

function parseiOSStringsFile {
    local filePath="$1"
    echo "Parsing iOS file $filePath"
    echo "Parsing XLIFF file $filePath"

sep="####"
$xidel --xpath "//file[contains(@original,'.storyboard') or contains(@original,'.xib') or contains(@original,'.strings')]//trans-unit/(concat(@id,'$sep',source/text(),'$sep',target/text()))" "$filePath" > /tmp/parsed.xml

    ios_ids=()
    ios_keys=()
    ios_values=()
    while read -r line || [[ -n $line ]]; do
	case $line in
	    (*"$sep"*)
	    id=${line%%"$sep"*}
            keyval=${line#*"$sep"}
	    key=${keyval%%"$sep"*}
	    value=${keyval#*"$sep"}
	    ;;
	    (*)
	    key=
	    value=
	    ;;
	esac
	if [ "$key" != "" ]; then
	    #echo "Adding mapping $key --> $value"
	    addiOSMapping "$id" "$key" "$value"
	fi
    done < "/tmp/parsed.xml"
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

sep="####"
$xidel --xpath "//file[contains(@original,'.storyboard') or contains(@original,'.xib') or contains(@original,'.strings')]//trans-unit/(concat(@id,'$sep',source/text(),'$sep',target/text()))" "/tmp/ZomTranslations/Base.xliff" > /tmp/base.xml

while read -r line || [[ -n $line ]]; do
    case $line in
	(*"$sep"*)
	id=${line%%"$sep"*}
	keyval=${line#*"$sep"}
	key=${keyval%%"$sep"*}
	value=${keyval#*"$sep"}
	value=${key}
	key=${id}
	;;
	(*)
	key=
	value=
	;;
    esac
    if [ "$key" != "" ]; then
	    # Cleanup key and value by removing quotes
	echo "Adding base mapping $key --> $value"
	addBaseMapping "$key" "$value"
    fi
done < "/tmp/base.xml"


# Extract strings from base android strings file, split into key-value pairs.
#
#
android_keys=()
android_values=()
android_count=0
while [ "x${android_input_files[android_count]}" != "x" ]
do
    thisfile="${android_input_files[android_count]}"
    parseAndroidStringsFile "$thisfile"
    ((android_count++))
done


# Match translated strings iOS<->Android. If they match, store the id mapping between them.
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
	#echo "Could not find Android string id for $term"
	#exit 1
	android_base_keys[i_translation]=""
    else
	echo "Lookup for $term is $id"
	android_base_keys[i_translation]="$id"
    fi
    ((i_translation++))
done

# Go through the iOS strings files, get the corresponding Android strings file and use the id mapping built in previous step to update the strings.
#
#
languages_index=0
while [ "x${languages[languages_index]}" != "x" ]
do
    language="${languages[languages_index]}"
    ios_file="/tmp/ZomTranslations/${language}.xliff"
    echo "Processing language: $language ios_file $ios_file"
    ((languages_index++))
    language_suffix=$(getAndroidLanguageCodeFromiOSLanguageCode "$language")
    
    android_keys=()
    android_values=()
    android_count=0
    while [ "x${android_input_files[android_count]}" != "x" ]
    do
	thisfile="${android_input_files[android_count]}"
	android_file="${thisfile/values/values$language_suffix}"
	if [ -f $android_file ]; then
	    parseAndroidStringsFile "$android_file"
	fi
	((android_count++))
    done
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
		#echo "Translation for $android_key is $translation"
		ios_values[count]="$translation"
	    fi
	fi
	((count++))
    done
    
    # Second pass: update the actual file
    echo "Update file $ios_file"
    count=0
    while [ "x${ios_keys[count]}" != "x" ]
    do
	id="${ios_ids[count]}"
	key="${ios_keys[count]}"
	value="${ios_values[count]}"
	if [ "$value" != "" ]; then
	    #echo "Update file $ios_file with $id: $key -> $value"
	    value="${value//&/&amp;}"
	    value="${value//</&lt;}"
	    value="${value//>/&gt;}"
	    export translation=${value}
	    perl -i~ -0777 -pe "s/(<trans-unit id=\"$id\">\s+<source>.*<\/source>)(\s+<target>.*<\/target>)?/\$1\n        <target>\$ENV{translation}<\/target>/g" "$ios_file"
	fi
	((count++))
    done

    # Update the xcode project
    echo "Update XCode project"
    rm -rf "${project_dir}/${language}.lproj/Localizable.strings"
    xcodebuild -importLocalizations -localizationPath "$ios_file" -project "$project_file"
done

