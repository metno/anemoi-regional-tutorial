module load LUMI/23.03 partition/G
module load cotainr/2023.11.0-cray-python-3.9.13.1

if [ "$3" = "" ]; then
    echo "Usage: create_container.sh <output name> <base image> <conda config>"
    exit
fi

cotainr build $1 --base-image=$2 --conda-env=$3
