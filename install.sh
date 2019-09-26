#!/bin/bash

set -e

echo "CADD-v1.5 (c) University of Washington, Hudson-Alpha Institute for Biotechnology and Berlin Institute of Health 2013-2019. All rights reserved."
echo ""

SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")

cd $BASEDIR

# check whether conda and snakemake are available

if [ "$(type conda)" == '' ]
then
    echo 'Conda seems not to be available. Are you sure conda is installed and available in the current $PATH ?';
    exit 1;
fi

usage="$(basename "$0") [-h] [-d] [-v <caddversion>] [-a] [-p] [-n] [-i] [-r] <reference-dir> -- CADD version 1.5

where:
    -h  show this help text
    -d  Install dependecies
    -v  Install CADD version (either GRCh37, GRCh38 or GRCh38v15 [default: GRCh37])
    -a  Download annotations
    -p  Download prescored variants with annotations
    -n  Download prescored variants without annotations
    -i  Download prescored indels. Only indels in ClinVar and gnomAD are included
    -r  Download references and annotations to this path [default: ${BASEDIR}/data]"

unset OPTARG
unset OPTIND

## Presets
ENV=false         # Download dependencies via conda
GRCh37=true       # Install CADD v1.4 for GRCh37
GRCh38=false      # Install CADD v1.4 for GRCh38
GRCh38v15=false   # Install CADD v1.5 for GRCh38
ANNOTATIONS=false # Dowload annotations
PRESCORE=true    # Download presecored snv variants
INCANNO=false     # Download prescored variants for scoring with annotations
NOANNO=false      # Download prescored variants for scoring without annotations
INDELS=false      # Download prescored indel variants. Only indels from ClinVar, gnomAD/TOPMed etc.
REFERENCE_DIR=${BASEDIR}/data

while getopts ':hdv:apnir:' option; do
  case "$option" in
    h) echo "$usage"
        exit
        ;;
    d) ENV=true
        ;;
    v) VERSION=$OPTARG
        ;;
    a) ANNOTATIONS=true
        ;;
    p) INCANNO=true
        ;;
    n) NOANNO=true
        ;;
    i) INDELS=true
        ;;
    r) REFERENCE_DIR=$OPTARG
        ;;
    :) echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
    \?) printf "illegal option: -%s\n" "$OPTARG" >&2
        echo "$usage" >&2
        exit 1
        ;;
  esac
done
shift $((OPTIND-1))

## Check version argument
if [ -n "$VERSION" ] && [ "$VERSION" != "GRCh37" ]; then
    GRCH37=false
    if [ "$VERSION" == "GRCh38" ]; then
        GRCh38=true
    elif [ "$VERSION" == "GRCh38v15" ]; then
        GRCh38v15=true
    else
       echo "illegal argument for option -v" >&2
       exit 1;
    fi
fi

## Convert potetnial relative path
REFERENCE_DIR=$(readlink -f "$REFERENCE_DIR" )

### FILE CONFIGURATION

ANNOTATION_GRCh37="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh37/annotationsGRCh37.tar.gz"
ANNOTATION_GRCh38="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh38/annotationsGRCh38.tar.gz"
ANNOTATION_GRCh38v15="http://krishna.gs.washington.edu/download/CADD/v1.5/GRCh38/annotationsGRCh38.tar.gz"
PRESCORE_GRCh37="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh37/whole_genome_SNVs.tsv.gz"
PRESCORE_GRCh38="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh38/whole_genome_SNVs.tsv.gz"
PRESCORE_GRCh38v15="http://krishna.gs.washington.edu/download/CADD/v1.5/GRCh38/whole_genome_SNVs.tsv.gz"
PRESCORE_INCANNO_GRCh37="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh37/whole_genome_SNVs_inclAnno.tsv.gz"
PRESCORE_INCANNO_GRCh38="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh38/whole_genome_SNVs_inclAnno.tsv.gz"
PRESCORE_INCANNO_GRCh38v15="http://krishna.gs.washington.edu/download/CADD/v1.5/GRCh38/whole_genome_SNVs_inclAnno.tsv.gz"
PRESCORE_GRCh37_INDEL="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh37/InDels.tsv.gz"
PRESCORE_GRCh38_INDEL="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh38/InDels.tsv.gz"
PRESCORE_GRCh38v15_INDEL="http://krishna.gs.washington.edu/download/CADD/v1.5/GRCh38/InDels.tsv.gz"
PRESCORE_INCANNO_GRCh37_INDEL="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh37/InDels_inclAnno.tsv.gz"
PRESCORE_INCANNO_GRCh38_INDEL="http://krishna.gs.washington.edu/download/CADD/v1.4/GRCh38/InDels_inclAnno.tsv.gz"
PRESCORE_INCANNO_GRCh38v15_INDEL="http://krishna.gs.washington.edu/download/CADD/v1.5/GRCh38/InDels_inclAnno.tsv.gz"

### OVERVIEW SELECTION

echo ""
echo "The following will be loaded: (disk space occupied)"

if [ "$ENV" = true ]
then
    if [ "$GRCh38v15" = 'true' ]
    then
        echo " - Setup of the virtual environment including all dependencies for CADD v1.5 (3 GB)."
    fi

    if [ "$GRCh38" = 'true' ] || [ "$GRCh37" = 'true' ]
    then
        echo " - Setup of the virtual environment including all dependencies for CADD v1.4 (3 GB)."
    fi
fi

if [ "$GRCh37" = true ]
then
    if [ "$ANNOTATIONS" = true ]
    then
        echo " - Download CADD annotations for GRCh37-v1.4 (98 GB)"
    fi

    if [ "$PRESCORE" = true ]
    then
        if [ "$INCANNO" = true ]
        then
            echo " - Download prescored SNV inclusive annotations for GRCh37-v1.4 (231 GB)"
            if [ "$INDELS" = true ]
            then
                echo " - Download prescored InDels inclusive annotations for GRCh37-v1.4 (3 GB)"
            fi
        fi
        if [ "$NOANNO" = true ]
        then
            echo " - Download prescored SNV (without annotations) for GRCh37-v1.4 (78 GB)"
            if [ "$INDELS" = true ]
            then
                echo " - Download prescored InDels (without annotations) for GRCh37-v1.4 (0.6 GB)"
            fi
        fi
    fi
fi

if [ "$GRCh38" = true ]
then
    if [ "$ANNOTATIONS" = true ]
    then
        echo " - Download CADD annotations for GRCh38-v1.4 (194 GB)"
    fi

    if [ "$PRESCORE" = true ]
    then
        if [ "$INCANNO" = true ]
        then
            echo " - Download prescored SNV inclusive annotations for GRCh38-v1.4 (323 GB)"
            if [ "$INDELS" = true ]
            then
                echo " - Download prescored InDels inclusive annotations for GRCh38-v1.4 (9 GB)"
            fi
        fi
        if [ "$NOANNO" = true ]
        then
            echo " - Download prescored SNV (without annotations) for GRCh38-v1.4 (79 GB)"
            if [ "$INDELS" = true ]
            then
                echo " - Download prescored InDels (without annotations) for GRCh38-v1.4 (1 GB)"
            fi
        fi
    fi
fi

if [ "$GRCh38v15" = true ]
then
    if [ "$ANNOTATIONS" = true ]
    then
        echo " - Download CADD annotations for GRCh38-v1.5 (168 GB)"
    fi

    if [ "$PRESCORE" = true ]
    then
        if [ "$INCANNO" = true ]
        then
            echo " - Download prescored SNV inclusive annotations for GRCh38-v1.5 (292 GB)"
            if [ "$INDELS" = true ]
            then
                echo " - Download prescored InDels inclusive annotations for GRCh38-v1.5 (7 GB)"
            fi
        fi
        if [ "$NOANNO" = true ]
        then
            echo " - Download prescored SNV (without annotations) for GRCh38-v1.5 (80 GB)"
            if [ "$INDELS" = true ]
            then
                echo " - Download prescored InDels (without annotations) for GRCh38-v1.5 (1 GB)"
            fi
        fi
    fi
fi

### INSTALLATION

if [ "$ENV" = true ]
then
    if [ "$GRCh38v15" = 'true' ]
    then
        echo "Setting up virtual environment for CADD v1.5"
        conda env create -f src/environment_v1.5.yml
    fi

    if [ "$GRCh38" = 'true' ] || [ "$GRCh37" = 'true' ]
    then
        echo "Setting up virtual environment for CADD v1.4"
        conda env create -f src/environment.yml
    fi

fi

# download a file and it index and check both md5 sums
function download_variantfile()
{
    echo $1
    wget -c $2
    wget -c $2.tbi
    wget $2.md5
    wget $2.tbi.md5
    md5sum -c *.md5
    rm *.md5
}

if [ "$GRCh37" = true ]
then
    if [ "$ANNOTATIONS" = true ]
    then
        echo "Downloading CADD annotations for GRCh37-v1.4 (98 GB)"
        if [ ! -d ${REFERENCE_DIR}/annotations ]; then
            mkdir ${REFERENCE_DIR}/annotations
        fi
        cd ${REFERENCE_DIR}/annotations/
        wget -c ${ANNOTATION_GRCh37} -O annotationsGRCh37.tar.gz
        wget ${ANNOTATION_GRCh37}.md5 -O annotationsGRCh37.tar.gz.md5
        md5sum -c annotationsGRCh37.tar.gz.md5
        echo "Unpacking CADD annotations for GRCh37-v1.4"
        tar -zxf annotationsGRCh37.tar.gz
        rm annotationsGRCh37.tar.gz
        rm annotationsGRCh37.tar.gz.md5
        mv GRCh37 GRCh37_v1.4
        cd $OLDPWD
    fi

    if [ "$PRESCORE" = true ]
    then
        if [ "$NOANNO" = true ]
        then
            mkdir -p ${REFERENCE_DIR}/prescored/GRCh37_v1.4/no_anno/
            cd ${REFERENCE_DIR}/prescored/GRCh37_v1.4/no_anno/
            download_variantfile "Downloading prescored SNV without annotations for GRCh37-v1.4 (78 GB)" ${PRESCORE_GRCh37}
            if [ "$INDELS" = true ]
            then
                download_variantfile "Downloading prescored InDels without annotations for GRCh37-v1.4 (1 GB)" ${PRESCORE_GRCh37_INDEL}
            fi
            cd $OLDPWD
        fi

        if [ "$INCANNO" = true ]
        then
            mkdir -p ${REFERENCE_DIR}/prescored/GRCh37_v1.4/incl_anno/
            cd ${REFERENCE_DIR}/prescored/GRCh37_v1.4/incl_anno/
            download_variantfile "Downloading prescored SNV inclusive annotations for GRCh37-v1.4 (231 GB)" ${PRESCORE_INCANNO_GRCh37}
            if [ "$INDELS" = true ]
            then
                download_variantfile "Downloading prescored InDels inclusive annotations for GRCh37-v1.4 (3 GB)" ${PRESCORE_INCANNO_GRCh37_INDEL}
            fi
            cd $OLDPWD
        fi
    fi
fi

if [ "$GRCh38" = true ]
then

    if [ "$ANNOTATIONS" = true ]
    then
        echo "Downloading CADD annotations for GRCh38-v1.4 (194 GB)"
        if [ ! -d ${REFERENCE_DIR}/annotations ]; then
            mkdir ${REFERENCE_DIR}/annotations
        fi
        cd ${REFERENCE_DIR}/annotations/
        wget -c $ANNOTATION_GRCh38 -O annotationsGRCh38.tar.gz
        wget $ANNOTATION_GRCh38.md5 -O annotationsGRCh38.tar.gz.md5
        md5sum -c annotationsGRCh38.tar.gz.md5
        echo "Unpacking CADD annotations for GRCh38-v1.4"
        tar -zxf annotationsGRCh38.tar.gz
        rm annotationsGRCh38.tar.gz
        rm annotationsGRCh38.tar.gz.md5
        mv GRCh38 GRCh38_v1.4
        cd $OLDPWD
    fi

    if [ "$PRESCORE" = true ]
    then
        if [ "$NOANNO" = true ]
        then
            mkdir -p ${REFERENCE_DIR}/prescored/GRCh38_v1.4/no_anno/
            cd ${REFERENCE_DIR}/prescored/GRCh38_v1.4/no_anno/
            download_variantfile "Downloading prescored SNV without annotations for GRCh38-v1.4 (79 GB)" ${PRESCORE_GRCh38}
            if [ "$INDELS" = true ]
            then
                download_variantfile "Downloading prescored InDels without annotations for GRCh38-v1.4 (1 GB)" ${PRESCORE_GRCh38_INDEL}
            fi
            cd $OLDPWD
        fi

        if [ "$INCANNO" = true ]
        then
            mkdir -p ${REFERENCE_DIR}/prescored/GRCh38_v1.4/incl_anno/
            cd ${REFERENCE_DIR}/prescored/GRCh38_v1.4/incl_anno/
            download_variantfile "Downloading prescored SNV inclusive annotations for GRCh38-v1.4 (323 GB)" ${PRESCORE_INCANNO_GRCh38}
            if [ "$INDELS" = true ]
            then
                download_variantfile "Downloading prescored InDels inclusive annotations for GRCh38-v1.4 (9 GB)" ${PRESCORE_INCANNO_GRCh38_INDEL}
            fi
            cd $OLDPWD
        fi
    fi
fi

if [ "$GRCh38v15" = true ]
then

    if [ "$ANNOTATIONS" = true ]
    then
        echo "Downloading CADD annotations for GRCh38-v1.5 (168 GB)"
        if [ ! -d ${REFERENCE_DIR}/annotations ]; then
            mkdir ${REFERENCE_DIR}/annotations
        fi
        cd ${REFERENCE_DIR}/annotations/
        wget -c ${ANNOTATION_GRCh38v15} -O annotationsGRCh38.tar.gz
        wget ${ANNOTATION_GRCh38v15}.md5 -O annotationsGRCh38.tar.gz.md5
        md5sum -c annotationsGRCh38.tar.gz.md5
        echo "Unpacking CADD annotations for GRCh38-v1.5"
        tar -zxf annotationsGRCh38.tar.gz
        rm annotationsGRCh38.tar.gz
        rm annotationsGRCh38.tar.gz.md5
        cd $OLDPWD
    fi

    if [ "$PRESCORE" = true ]
    then
        if [ "$NOANNO" = true ]
        then
            mkdir -p ${REFERENCE_DIR}/prescored/GRCh38_v1.5/no_anno/
            cd ${REFERENCE_DIR}/prescored/GRCh38_v1.5/no_anno/
            download_variantfile "Downloading prescored SNV without annotations for GRCh38-v1.5 (80 GB)" ${PRESCORE_GRCh38v15}
            if [ "$INDELS" = true ]
            then
                download_variantfile "Downloading prescored InDels without annotations for GRCh38-v1.5 (1 GB)" ${PRESCORE_GRCh38v15_INDEL}
            fi
            cd $OLDPWD
        fi

        if [ "$INCANNO" = true ]
        then
            mkdir -p ${REFERENCE_DIR}/prescored/GRCh38_v1.5/incl_anno/
            cd ${REFERENCE_DIR}/prescored/GRCh38_v1.5/incl_anno/
            download_variantfile "Downloading prescored SNV inclusive annotations for GRCh38-v1.5 (292 GB)" ${PRESCORE_INCANNO_GRCh38v15}
            if [ "$INDELS" = true ]
            then
                download_variantfile "Downloading prescored InDels inclusive annotations for GRCh38-v1.5 (9 GB)" ${PRESCORE_INCANNO_GRCh38v15_INDEL}
            fi
            cd $OLDPWD
        fi
    fi
fi
