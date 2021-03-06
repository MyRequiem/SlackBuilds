#! /bin/sh

showHelp() {
cat << EOF
Usage: $(basename "$0") archive mode [output]

-h, --help  - Show this message

archive     - Name of source files archive in the current directory.
                Should be in this format: name-version.tar.(gz|xz|bz2)

Parameter mode can be 3 types:
-s          - Create slack-desc file
-d          - Create doinst.sh file
string      - Configure options. For example:
                "--prefix=/usr --libdir=/usr/lib64 --enable-static=yes"
                "no" - without parameters
output      - Package will be created in otput dir (only with string config).
                If output not specified, the package will be created in /tmp
EOF

    exit
}

createSlackDesc() {
    SD=${CWD}/slack-desc
    echo "Creating file: ${SD}"

cat << EOF > "${SD}"
# HOW TO EDIT THIS FILE:
# The "handy ruler" below makes it easier to edit a package description.  Line
# up the first '|' above the ':' following the base package name, and the '|'
# on" the right side marks the last column you can put a character in.
# You must make exactly 11 lines for the formatting to be correct.  It's also
# customary to leave one space after the ':'."

        |-----handy-ruler------------------------------------------------------|
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
$PKGNAME:
EOF
    echo Done
    exit
}

createDoinst() {
    DI=${CWD}/doinst.sh
    echo "Creating file: ${DI}"

cat << EOF > "${DI}"
# Update the desktop database:
if [ -x /usr/bin/update-desktop-database ]; then
    /usr/bin/update-desktop-database /usr/share/applications >/dev/null 2>&1
fi

# Update hicolor theme cache:
if [ -e /usr/share/icons/hicolor/icon-theme.cache ]; then
    if [ -x /usr/bin/gtk-update-icon-cache ]; then
        /usr/bin/gtk-update-icon-cache /usr/share/icons/hicolor >/dev/null 2>&1
    fi
fi

# Update the mime database:
if [ -x /usr/bin/update-mime-database ]; then
    /usr/bin/update-mime-database /usr/share/mime >/dev/null 2>&1
fi

EOF
    echo Done
    exit
}

configure() {
    CFLAGS="${SLKCFLAGS}" \
    CXXFLAGS="${SLKCFLAGS}" \
    ./configure "${PARAMCONFIG}"
}

if [[ $# != 2 && $# != 3 ]]; then
    showHelp
fi

SRCNAME=$(basename "$1" 2>/dev/null)
if [ -z "${SRCNAME}" ]; then
    echo -e "\033[0;31mIncorrect file name:\033[0m $1"
    exit
fi

if ! [ -f "${SRCNAME}" ]; then
    echo -en "\033[0;31mError:\033[0m File \033[1;34m${SRCNAME}\033[0m "
    echo -e "not found in the current directory (-h or --help for help)"
    exit
fi

if ! echo "${SRCNAME}" | grep -qE "\.tar\.(g|b|x)z2?$"; then
    echo -en "File \033[1;34m${SRCNAME}\033[0m is not an archive on format "
    echo "tar.gz, tar.xz or tar.bz2"
    exit
fi

PKGNAME=$(echo "$SRCNAME" | rev | cut -f 3- -d . | cut -f 2- -d - | rev)
PKGVER=$(echo "$SRCNAME" | rev | cut -f 3- -d . | cut -f 1 -d - | rev)
if [ -z "${PKGNAME}" ] || \
        [ -z "${PKGVER}" ] || \
        [ "${PKGNAME}" = "${PKGVER}" ]; then
    echo "Name of archive source files hould be in this format:"
    echo "    name-version.tar.(gz|xz|bz2)"
    exit
fi

BUILD="myreq"
PKGTYPE=${PKGTYPE:-txz}

if [ -z "$ARCH" ]; then
  case "$(uname -m)" in
    i?86)
        ARCH=i486
        ;;
    arm*)
        ARCH=arm
        ;;
    *)
       ARCH=$(uname -m)
       ;;
  esac
fi

if [ "$ARCH" = "i486" ]; then
    SLKCFLAGS="-O2 -march=i486 -mtune=i686"
    LIBDIRSUFFIX=""
elif [ "$ARCH" = "x86_64" ]; then
    SLKCFLAGS="-O2 -fPIC"
    LIBDIRSUFFIX="64"
else
    SLKCFLAGS="-O2"
    LIBDIRSUFFIX=""
fi

CWD=$(pwd)
if [ $# -eq 2 ]; then
    case $2 in
        -s)
            createSlackDesc
            ;;
        -d)
            createDoinst
            ;;
    esac
fi

PARAMCONFIG=$2
if [ "$2" = "no" ]; then
    PARAMCONFIG=""
fi

OUTPUTDIR="/tmp"
if [ -d "$3" ]; then
    OUTPUTDIR=$(echo "$3" | sed 's/\/$//')
    case ${OUTPUTDIR} in
        /*) # full pass
            ;;
        *)  # relative path
            OUTPUTDIR=${CWD}/${OUTPUTDIR}
            ;;
    esac
elif [ $# -eq 3 ]; then
    echo -e "\033[0;31mNo such directory:\033[0m $3"
    exit
fi

if ! [ -f "${CWD}"/slack-desc ]; then
    echo -e "\033[0;31mMissing file:\033[0m ${CWD}/slack-desc"
    echo "-h or --help for help"
    exit
fi

if ! [ -f "${CWD}"/doinst.sh ]; then
    echo -e "\033[0;31mMissing file:\033[0m ${CWD}/doinst.sh"
    echo "-h or --help for help"
    exit
fi

rm -rf "${OUTPUTDIR}"/"${PKGNAME}"-build
mkdir -p "${OUTPUTDIR}"/"${PKGNAME}"-build/"${PKGNAME}"
cd "${OUTPUTDIR}"/"${PKGNAME}"-build || exit 1

TYPESRC=$(echo "$SRCNAME" | rev | cut -f 1 -d . | rev)
[ "${TYPESRC}" = "gz" ] && tar -xvzf "${CWD}"/"${SRCNAME}"
[ "${TYPESRC}" = "bz2" ] && tar -xvjf "${CWD}"/"${SRCNAME}"
[ "${TYPESRC}" = "xz" ] && tar -xvJf "${CWD}"/"${SRCNAME}"

cd "${PKGNAME}"-"${PKGVER}" || exit 1

chown -R root:root .
find . \( \
    -perm 777 -o \
    -perm 775 -o \
    -perm 711 -o \
    -perm 555 -o \
    -perm 511 \) -exec chmod 755 {} \;
find . \( \
    -perm 666 -o \
    -perm 664 -o \
    -perm 600 -o \
    -perm 444 -o \
    -perm 440 -o \
    -perm 400 \) -exec chmod 644 {} \;

if [ -x ./configure ]; then
    configure
elif [ -x ./autogen.sh ]; then
    ./autogen.sh
    configure
else
    autoreconf -f -i && configure
fi

if [ -f ./Makefile ]; then
    make || exit
else
    mkdir build
    cd build || exit 1
    cmake \
    -DCMAKE_C_FLAGS="${SLKCFLAGS}" \
    -DCMAKE_CXX_FLAGS="${SLKCFLAGS}" \
    -DLIB_SUFFIX="${LIBDIRSUFFIX}" \
    -DCMAKE_INSTALL_PREFIX=/usr ..
    make || exit
fi

make install DESTDIR="${OUTPUTDIR}"/"${PKGNAME}"-build/"${PKGNAME}" || exit

cd "${OUTPUTDIR}"/"${PKGNAME}"-build/"${PKGNAME}" || exit 1
mkdir install
# if file size is not zero
if [ "$(stat -c%s doinst.sh)" != "0" ]; then
    cp "${CWD}"/doinst.sh install
fi
cp "${CWD}"/slack-desc install

# docs
mkdir -p usr/doc/"${PKGNAME}"-"${PKGVER}"
cp "${CWD}"/slack-desc usr/doc/"${PKGNAME}"-"${PKGVER}"
find "${OUTPUTDIR}"/"${PKGNAME}"-build/"${PKGNAME}"-"${PKGVER}" \
        -maxdepth 1 -type f -a \( \
    -iname '*AUTHORS*' -o \
    -iname '*COPYING*' -o \
    -iname '*ChangeLog*' -o \
    -iname '*INSTALL*' -o \
    -iname '*NEWS*' -o \
    -iname '*README*' -o \
    -iname '*TODO*' -o \
    -iname '*MANIFEST*' -o \
    -iname '*version*' \
    \) -exec cp {} usr/doc/"${PKGNAME}"-"${PKGVER}" \;

/sbin/makepkg -l y -c n \
    "${OUTPUTDIR}"/"${PKGNAME}"-"${PKGVER}"-"${ARCH}"-"${BUILD}"."${PKGTYPE}"
