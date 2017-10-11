find ../.. -not -path "*Submodules*" -and -not -path "*Pods*" -and -not -path "*DerivedData*" -and -not -path "*Carthage*"  -and \( -name "*.swift" -or -name "*.h" -or -name "*.m" \) -print0 | xargs -0 genstrings -o /tmp/

my_dir="$(dirname "$0")"
. "$my_dir/stringtool.sh" ../Zom/Base.lproj/Localizable.strings /tmp/Localizable.strings -union ../../ChatSecure/OTRResources/Localizations/Base.lproj/Localizable.strings -union > /tmp/Localizable.strings.utf8
iconv -f utf-8 -t utf-16 /tmp/Localizable.strings.utf8 > ../Zom/Base.lproj/Localizable.strings

