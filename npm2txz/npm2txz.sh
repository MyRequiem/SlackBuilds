#!/bin/sh

SCRIPT_NAME="$(basename "$0")"
if [[ "x$(id -u)" == "x0" ]]; then
    echo "${SCRIPT_NAME} should be run as a normal user."
    exit 1
fi

# check npm command
if ! command -v npm &>/dev/null; then
    echo "npm: command not found."
    echo -n "You need to install package \"nodejs\" or "
    echo "\"nodejs-bin\" from SBo repository."
    exit 1
fi

# check param (node module name)
if [[ "x$1" == "x" || \
        "x$1" == "x--help" || \
        "x$1" == "x-h" ]]; then
    echo "Usage: ${SCRIPT_NAME} module_name"
    exit 0
fi

# package name can be specified with a postfix or without it:
#    development or pre-release version
#       $ ./nmp2txz.sh instant-markdown-d@next
#    latest stable version
#       $ ./nmp2txz.sh instant-markdown-d
#       $ ./nmp2txz.sh instant-markdown-d@latest
PKGNAME=$(echo "$1" | cut -d "@" -f 1)
BUILD=""
TAG="myreq"
PKGTYPE="txz"
OUTPUT="$(pwd)"
TMP="/tmp/${PKGNAME}-build/"

sudo rm -rf "${TMP}"
mkdir -p "${TMP}"
cd "${TMP}" || exit 1

DESTDIR=./ npm install -g "$1" || exit 1

ARCH=""
[ "$(uname -m)" == "x86_64" ] && ARCH="64"

if [ "${PKGNAME}" == "markdownlint" ]; then
    [ -n "${ARCH}" ] && mv usr/lib usr/lib64
    mkdir -p usr/bin
    (
        cd usr/bin || exit 1
        MARKDOWN="../lib${ARCH}/node_modules/markdownlint/node_modules/\
markdown-it/bin/markdown-it.js"
        chmod 755 "${MARKDOWN}"
        ln -s "${MARKDOWN}" "${PKGNAME}"
    )
elif [ -n "${ARCH}" ]; then
    mv usr/lib usr/lib64
    (
        cd usr/bin || exit 1
        FILES=$(ls)
        for FILE in ${FILES}; do
            if [ -L "${FILE}" ]; then
                TARGET=$(readlink "${FILE}")
                sudo rm "${FILE}"
                ln -s "$(echo "${TARGET}" | sed -e 's/\/lib\//\/lib64\//g')" \
                    "${FILE}"
            fi
        done
    )
fi

# remove empty /usr/etc directory
[ -d usr/etc ] && \
    [[ "x$(find usr/etc -type f -o -type l  | wc -l)" == "x0" ]] && \
    sudo rm -rf usr/etc

JSON="usr/lib${ARCH}/node_modules/${PKGNAME}/package.json"
VERSION=$(grep -i "\"version\":" "${JSON}" | cut -d \" -f 4 | tr "-" "_")
DESCRIPTION=$(grep -i "\"description\":" "${JSON}" | cut -d \" -f 4)
HOMEPAGE=$(grep -i "\"homepage\":" "${JSON}" | cut -d \" -f 4)

mkdir install
PKGNAME="${PKGNAME}_npm"

cat << EOF > install/slack-desc
# HOW TO EDIT THIS FILE:
# The "handy ruler" below makes it easier to edit a package description.  Line
# up the first '|' above the ':' following the base package name, and the '|'
# on the right side marks the last column you can put a character in.  You must
# make exactly 11 lines for the formatting to be correct.  It's also
# customary to leave one space after the ':'.
       |-----handy-ruler-------------------------------------------------------|
${PKGNAME}: (${PKGNAME})
${PKGNAME}:
${PKGNAME}:
${PKGNAME}: ${DESCRIPTION}
${PKGNAME}:
${PKGNAME}:
${PKGNAME}:
${PKGNAME}:
${PKGNAME}:
${PKGNAME}: Homepage: ${HOMEPAGE}
${PKGNAME}:
EOF

sudo chown -R root:root .
sudo find . \( \
        -perm 777 -o \
        -perm 775 -o \
        -perm 711 -o \
        -perm 555 -o \
        -perm 511 \
    \) -exec chmod 755 {} \; \
    -o \( \
        -perm 666 -o \
        -perm 664 -o \
        -perm 600 -o \
        -perm 444 -o \
        -perm 440 -o \
        -perm 400 \
    \) -exec chmod 644 {} \;

PACKAGE="${OUTPUT}/${PKGNAME}-${VERSION}-noarch-${BUILD}${TAG}.${PKGTYPE}"
sudo rm -f "${PACKAGE}"
sudo /sbin/makepkg -l y -c n "${PACKAGE}"
