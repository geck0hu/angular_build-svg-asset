#!/bin/bash
# ver 1.0
# gkortvelyessy@gmail.com
#
# Intended to generate a standalone svg file compatible with the angular API (1.5.5)
#  associtaions defined in the main JS file under the `<!-- SVG ASSETS --' block
#  each svg file has to have a filename ending `.svg' and must have an assigned name in the table above
#
# Example:
#
#  <!-- SVG ASSETS -- 
#  +-----------------------------------+---------------------------+
#  | baseline-account_box-24px.svg     | account_box               |
#  | baseline-account_circle-24px.svg  | account                   |
#  | baseline-mail-24px.svg            | email                     |
#  | baseline-phone-24px.svg           | phone                     |
#  +-----------------------------------+---------------------------+
#  -->
#
# mandatory dependencies:
# - inkscape [tested with version 0.92.3]
#

# Ignore the question is escape required - the script deals with it
FILED_DELIMITER="|"
BOX_DRAWING_VERTICAL="|"


# However you need to consciously use the escape character `\' within these two variables
BEGIN="<svg>
 <!-- Generated using https://github.com/geck0hu/angular_build-svg-asset -->
  <defs>
"

END="
  </defs>
</svg>"


if ! command -v inkscape &>/dev/null; then
  echo "Dependency missing! Please install inkscape" >&2
  echo "- debian/ubuntu: apt-get install inkscape" >&2
  exit 2
fi

SCRIPT=$(basename $0)

if [[ ! -f "$1" ]]; then
  echo "Usage: ${SCRIPT} <js_file_with_table> [path_to_icons]" >&2
  echo " see header of this script for further details" >&2
  exit 1
fi

if [[ $# = 2 ]]; then
  [[ -d "$2" ]] && ICON_PATH="$2/" || echo "Wrong path: $2" >&2
fi

# adding escape character if required
printf -v ESCD_DELIM "%q" "${FILED_DELIMITER}"
printf -v ESCD_BOX_CHAR "%q" "${BOX_DRAWING_VERTICAL}"

fileids_str="fileids=( $(sed -n '/<!-- SVG ASSETS --/,/-->/p' "$1" | sed -E "s/^\s*${ESCD_BOX_CHAR}\s*(\S+)\.svg\s*${ESCD_DELIM}\s*(\S+)\s*${ESCD_BOX_CHAR}.*$/\'\1.svg\' \'\2\'/g;t;d") )"
eval "${fileids_str}"

TMP_SVG="$(mktemp -u).svg"
trap "[ -f /${TMP_SVG} ] && rm ${TMP_SVG}" EXIT


for (( idx=0 ; idx<${#fileids[@]} ; idx+=2 )) ; do
  FILE="${ICON_PATH}${fileids[idx]}"
  gcontent="  "
  if [[ -f "$FILE" ]]; then
    if [[ ! "$(file -L --mime-type "$FILE")" =~ "image/svg" ]]; then
      echo "Not an SVG file: $FILE" >&2
    else
      SVG_ID="${fileids[idx+1]}"
      filename="${FILE##*/}"
      gcontent="${gcontent} <!-- ${filename} --><g id=\""
      gcontent="${gcontent}${SVG_ID}\">"
      inkscape --vacuum-defs --export-plain-svg="$TMP_SVG" "$FILE"
      gcontent="${gcontent}$(sed -n '/<defs/,/<\/svg>/{/<defs/d;/<\/svg>/d;p}' "${TMP_SVG}" | sed -E 's/^ +id=.+$//' | tr -d '\n')"
      gcontent="${gcontent}</g>"
      SVG_G_CONTENT="${SVG_G_CONTENT}${gcontent}"
      [[ $((idx+2)) -lt ${#fileids[@]} ]] && SVG_G_CONTENT="${SVG_G_CONTENT}"$'\n'
    fi
  else
    echo "SVG File not found: $FILE" >&2
  fi
done

echo "${BEGIN}${SVG_G_CONTENT}${END}"
