---
layout: post
title:  "Getting started on LUMI"
date:   2024-06-14 09:00:00 +0200
author: Aram Farhad Salihi (arams@met.no), Even Nordhagen, and Thomas Nipen (thomasn@met.no)
order: 1
tags: LUMI HPC containers
---

A pre-requisite for this tutorial is that you have a LUMI-G account and are able to log in to the system with ssh.

## Building a container

On LUMI, containers should be used in order to reduce strain onf the lustre file system. The general strategy
is to build a singularity container with all dependencies, and leave code that you frequently edit (e.g.
Anemoi and aifs-mono) in a virtual environment outside the container. We do this since building a
container takes a while and we don't want to wait for this every time we change a line of python code.

LUMI and AMD has built custom images of ROCM (5.4.1 up to 5.6.1) that is optimized for LUMI. We want to use this for optimal
performance instead of installing the dependency. It is worth mentioning that these images contains special libraries that enables
efficient communications between nodes and GPUs (HPE CRAY libfabric, HPE CRAY MPICH, RCCL and aws-ofi-rccl) which uses HPE Slingshot 11 high-speed interconnect. 
These prebuilt images are located at:

{% highlight bash %}
/appl/local/containers/sif-images/
{% endhighlight %}

It is adviced to copy and use rocm images to your project folder (at path /scratch/project_xxxxxxxxx). For this illustration we will consider the sif image:
`lumi-rocm-rocm-5.6.1.sif`. When the file is copied over to your project folder, we can use the tool "cotainr" to build the container. 
In order to build with cotainr, which is a loadable user-module, it can be incooperated into your bash script in order to simplify the building process.
Create a file called `create_container.sh`, and copy the following lines:

{% highlight bash %}
module load LUMI/23.03 partition/G
module load cotainr/2023.11.0-cray-python-3.9.13.1

cotainr build $1 --base-image=$2 --conda-env=$3
{% endhighlight %}

Remember to add execution premission (`chmod +x create_container.sh`) in order to run.
The first input argument represents the name of your container, second argument is your copied base image (e.g `lumi-rocm-rocm-5.6.1.sif`) and last is yaml file stating 
which python packages that should be included within the container. An example of the envirorment yaml file could be:

{% highlight yaml%}
name: name_of_your_env
channels:
  - conda-forge
  - pyg
dependencies:
  - certifi=2023.07.22
  - charset-normalizer=3.2.0
  - filelock=3.12.4
  - idna=3.4
  - jinja2=3.1.2
  - lit=16.0.6
  - markupsafe=2.1.3
  - mpmath=1.3.0
  - pytorch_scatter=2.1.2
  - numpy=1.25.2
  - pillow=10.0.0
  - pip=23.2.1
  - python=3.11.5
  - sympy=1.12
  - typing-extensions=4.7.1
  - urllib3=2.0.4
  - pip:
      - --extra-index-url https://download.pytorch.org/whl/rocm5.6
      - torch==2.2.0+rocm5.6
      - torchaudio==2.2.0+rocm5.6
      - torchvision==0.17.0+rocm5.6
      - pytorch-triton-rocm
      - triton
      - zarr
      - trimesh
      - eccodes
      - plotly
      - torchview
      - graphviz
      - mlflow-export-import
      - cfgrib
      - xarray
      - netCDF4==1.6.5
      - pyyaml
      - ruamel.yaml
      - boto3
      - botocore
      - climetlab
      - einops
      - matplotlib
      - wandb
      - pytorch-lightning==2.1.0
      - timm
      - hydra-core
      - ecml-tools[data,provenance]
      - tqdm
      - pre-commit
      - networkx
      - h3
      - torchinfo
      - dask
      - rich
      - memray
      - tabulate
      - mlflow
      - pyshtools
      - pandas
      - scikit-image
      - torch_geometric==2.4.0
      - anemoi-utils[provenance]>=0.3
      - git+https://github.com/metno/anemoi-datasets.git@feature-branch
      - anemoi-models@git+https://github.com/metno/anemoi-models.git@feature/graph_refactor
{% endhighlight %}
Notice if you want add more python packages you can either place it under dependencies or pip.
To build the container, run the following:

{% highlight bash %}
./create_container name_of_file.sif lumi-rocm-rocm-5.6.1.sif name_of_your_env.yaml
{% endhighlight %}

This will create a container called `name_of_file.sif`, and takes approximately 10-12 minutes.

NOTE: If in the future, the aifs-mono codebase requires new dependencies, or newer versions of existing
dependencies, you will have to build a new container. It is therefore good practice to organize how you name
your containers.

## Setting up Anemoi and aifs-mono

Next, we will create a virtual environment with the repositories that we want to override. Note that we did
install Anemoi and aifs-mono in the container, but by installing them in a virtual environment outside the
container, we can override the code from the container as the packages from the virtual environment are loaded
preferentially over the packages in the container.

Create a virtual environment:
{% highlight bash %}
mkdir work
cd work
virtualenv .venv
{% endhighlight %}

Then clone and install the repositories we want:

{% highlight bash %}
source .venv/bin/activate
git clone git@github.com:ecmwf-lab/aifs-mono
git clone git@github.com:ecmwf/anemoi-datasets
pip install -e aifs-mono
pip install -e anemoi-datasets
{% endhighlight %}

NOTE: These repositories have been installed in editable mode, which means that if you change the code within
the repositories, the code will be use immediately when referring to them in the virtual environment.

## Setting up a job script

To train a model, you need to set up a job script that loads the virtual environment and runs the container. In this example, we will call the script `job_script.sh`:

{% highlight bash %}
#!/bin/bash
#SBATCH --output=logs/slurm.out
#SBATCH --error=logs/slurm.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --account=<your_project_name_or_number>
#SBATCH --partition=dev-g
#SBATCH --gpus-per-node=8
#SBATCH --time=02:00:00
#SBATCH --job-name=aifs

module load LUMI/23.09 partition/G

export SINGULARITYENV_LD_LIBRARY_PATH=/opt/ompi/lib:${EBROOTAWSMINOFIMINRCCL}/lib:/opt/cray/xpmem/2.4.4-2.3_9.1__gff0e1d9.shasta/lib64:${SINGULARITYENV_LD_LIBRARY_PATH}

# run run-pytorch.sh
srun --cpu-bind=map_cpu:49,57,17,25,1,9,33,41 \
singularity exec -B /pfs:/pfs \
	         -B /var/spool/slurmd,/opt/cray/,/usr/lib64/libcxi.so.1,/usr/lib64/libjansson.so.4 \
		 <full_path_to_container>.sif \
		 <full_path_to_job_script>run-pytorch.sh
{% endhighlight %}

Notice that in order to fully utilize LUMI's hardware we have included correct cpu binding and paths to different compiled files. The job script will then execute
a bash script called `run-pytorch.sh` (remember to add execution premission `chmod +x run-pytorch.sh` in order to run) which includes fetching node names and enables 
exports to utilize the interconnect.

{% highlight bash %}
#!/bin/bash

# This script is meant to be executed by job_script.sh

aifsdir=<full_patj_to_aifs_repo>

# Printing GPU information to terminal once
if [ $SLURM_LOCALID -eq 0 ] ; then
    rocm-smi
fi
sleep 2

# MIOPEN needs some initialisation for the cache as the default location
# does not work on LUMI as Lustre does not provide the necessary features.
export MIOPEN_USER_DB_PATH="/tmp/$(whoami)-miopen-cache-$SLURM_NODEID"
export MIOPEN_CUSTOM_CACHE_DIR=$MIOPEN_USER_DB_PATH

if [ $SLURM_LOCALID -eq 0 ] ; then
    rm -rf $MIOPEN_USER_DB_PATH
    mkdir -p $MIOPEN_USER_DB_PATH
fi
sleep 2

# Optional! Set NCCL debug output to check correct use of aws-ofi-rccl (these are very verbose)
#export NCCL_DEBUG=INFO
export NCCL_DEBUG=WARN
export NCCL_DEBUG_SUBSYS=INIT,COLL

# Set interfaces to be used by RCCL.
# This is needed as otherwise RCCL tries to use a network interface it has
# no access to on LUMI.
export NCCL_SOCKET_IFNAME=hsn0,hsn1,hsn2,hsn3
export NCCL_NET_GDR_LEVEL=3

# Set ROCR_VISIBLE_DEVICES so that each task uses the proper GPU
#export ROCR_VISIBLE_DEVICES=1,2,3,4 #$SLURM_LOCALID

# Report affinity to check
echo "Rank $SLURM_PROCID --> $(taskset -p $$); GPU $ROCR_VISIBLE_DEVICES"

# Function to find an unused TCP port starting from a specified port number.
find_unused_port() {
    local port=$1
    while : ; do
        # Check if the port is in use
        if ! ss -tuln | grep -qE ":::$port|0.0.0.0:$port" ; then
            # Port is not in use
            echo $port
            break
        fi
        # Increment port by 1 and check again.
        ((port++))
    done
}

# fetches slurm nodelist

get_master_node() {
    # Get the first item in the node list
    first_nodelist=$(echo $SLURM_NODELIST | cut -d',' -f1)

    if [[ "$first_nodelist" == *'['* ]]; then
        # Split the node list and extract the master node
        base_name=$(echo "$first_nodelist" | cut -d'[' -f1)
        range_part=$(echo "$first_nodelist" | cut -d'[' -f2 | cut -d'-' -f1)
        master_node="${base_name}${range_part}"
    else
        # If no range, the first node is the master node
        master_node="$first_nodelist"
    fi

    echo "$master_node"
}



export MASTER_ADDR=$(get_master_node)
export MASTER_PORT=$(find_unused_port 29500)
export WORLD_SIZE=$SLURM_NPROCS
export RANK=$SLURM_PROCID

echo $MASTER_PORT
# CXI stuff
export CXI_FORK_SAFE=1
export CXI_FORK_SAFE_HP=1
export FI_CXI_DISABLE_CQ_HUGETLB=1

# Enable verbose hydra error outputs
export HYDRA_FULL_ERROR=1

python "$aifsdir"/<path_to_train_script>.py

{% endhighlight %}
To run the job, do this:

{% highlight bash %}
sbatch job_script.sh
{% endhighlight %}
