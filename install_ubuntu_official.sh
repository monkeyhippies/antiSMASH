#!/bin/bash

function display_help() {
    echo "install_ubuntu.sh [options]"
    echo ""
    echo "--base, -b URL    Use URL as base URL for antiSMASH tarball"
    echo "--help, -h        Display this help"
}

while true; do
    case "$1" in
        -h|--help) display_help; exit 0;;
        -b|--base) ANTISMASH_ALTERNATIVE_BASE=$2; shift; shift ;;
        "") break;;
        *) display_help; exit 1;;
    esac
done

VERSION="antismash-2.0.2"

TMPDIR=/tmp

ARCH=$(uname -m)

BLAST_URL_ROOT="ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/"
BLAST_PACKAGE="ncbi-blast-2.2.29+-1.${ARCH}.rpm"

GLIMMERHMM_REPO="git://github.com/kblin/glimmerhmm.git"

ANTISMASH_BASE_BITBUCKET="https://bitbucket.org/antismash/antismash2/downloads"
ANTISMASH_BASE=${ANTISMASH_ALTERNATIVE_BASE:-$ANTISMASH_BASE_BITBUCKET}
ANTISMASH_TARBALL="${VERSION}.${ARCH}.tar.bz2"

ANTISMASH_CFG="${HOME}/.antismash.cfg"

function die {
    echo $@
    exit 1
}

function install_common {
    sudo apt-get update || die "Failed to update packages"
    sudo apt-get install -y hmmer hmmer-compat alien build-essential \
                            python-svg python-excelerator python-matplotlib \
                            alien muscle default-jre tigr-glimmer glimmerhmm \
                            zlib1g-dev python-virtualenv python-pip git-core \
                            python-dev libxml2-dev libxslt-dev || die "Failed to install extra packages"

    if [ ! $(which blastp) ]; then
        pushd $TMPDIR
        wget "${BLAST_URL_ROOT}${BLAST_PACKAGE}" || die "Failed to fetch blast package"
        sudo alien -i "$BLAST_PACKAGE" || die "Failed to install blast package"
        popd
    fi
}

function install_10_04 {
    sudo apt-get install -y python-software-properties || die "Failed to install add-apt-repository"
    sudo add-apt-repository ppa:kai-blin-biotech/ppa || die "Failed to set up extra PPA"
    install_common
    export VIRTENV_OPTIONS=""
}

function install_12_04 {
    sudo apt-get install -y python-software-properties || die "Failed to install add-apt-repository"
    sudo add-apt-repository -y ppa:kai-blin-biotech/ppa || die "Failed to set up extra PPA"
    install_common
}

function install_12_10 {
    sudo apt-get install -y software-properties-common || die "Failed to install add-apt-repository"
    sudo add-apt-repository -y ppa:kai-blin-biotech/ppa || die "Failed to set up extra PPA"
    install_common
    export VIRTENV_OPTIONS="--system-site-packages"
}

function install_13_04 {
    sudo apt-get install -y software-properties-common || die "Failed to install add-apt-repository"
    sudo add-apt-repository -y ppa:kai-blin-biotech/ppa || die "Failed to set up extra PPA"
    install_common
    export VIRTENV_OPTIONS="--system-site-packages"
}

function install_13_10 {
    sudo apt-get install -y software-properties-common || die "Failed to install add-apt-repository"
    sudo add-apt-repository -y ppa:kai-blin-biotech/ppa || die "Failed to set up extra PPA"
    install_common
    export VIRTENV_OPTIONS="--system-site-packages"
}

function get_release_number {
    NUM=$(lsb_release -rs)
    echo ${NUM/\./_}
}


function handle_install {
    HELPER="install_$(get_release_number)"
    $HELPER || \
    die "Installer not set up for Ubuntu $(lsb_release -rs), please contact antismash@biotech.uni-tuebingen.de"
}

function pip_or_die {
    PACKAGE=$1
    pip install ${PACKAGE} || die "Failed to install ${PACKAGE}"
}

function get_antismash {
    pushd "${SOFTDIR}"
    virtualenv $VIRTENV_OPTIONS sandbox
    source sandbox/bin/activate
    pip install --upgrade pip
    pip install --upgrade --no-use-wheel setuptools
    pip_or_die argparse
    pip_or_die "straight.plugin==1.4.0-post-1"
    pip_or_die "cssselect==0.7.1"
    pip_or_die "lxml==3.2.3"
    pip_or_die "pyquery==1.2.4"
    pip_or_die numpy
    pip_or_die "biopython>=1.62"
    pip_or_die helperlibs
    wget -N "${ANTISMASH_BASE}/${ANTISMASH_TARBALL}"
    tar --strip-components=1 -xf ${ANTISMASH_TARBALL}
    python download_databases.py
    popd
}

######################
# Actually do the work
######################

echo "getting '${ANTISMASH_BASE}/${ANTISMASH_TARBALL}'"

handle_install

get_antismash

cat > ${ANTISMASH_CFG} <<EOF
[glimmer]
basedir = /usr/lib/tigr-glimmer
EOF

cat > run_antismash <<EOF
#!/bin/bash
source $(pwd)/sandbox/bin/activate
$(pwd)/run_antismash.py \$*
EOF

chmod a+x run_antismash

echo "Done installing antiSMASH. To run, put the 'run_antismash' wrapper script into your path."
