---
layout: post
title:  "Getting started on LUMI"
date:   2024-06-14 09:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
tags: anemoi
---

To get started on LUMI, you need an account.

## Building a container

AMD has build a custom version of PyTorch that is optimized for LUMI. We want to use this for optimal
performance. The general strategy for running on LUMI is to build a singularity container that contains all
dependencies. The actual code that we will frequently work on (Anemoi and aifs-mono) will be kept outside the
container, since building a container takes a while and we don't want to wait for this every time we change a
line of code.

The first step is to set up a cotainer recipe:

{% highlight yaml %}
requirements:
   numpy
   anemoi-datasets
{% endhighlight %}

To build the container, run the following:

{% highlight bash %}
build
{% endhighlight %}

## Setting up Anemoi and aifs-mono

Next, we will create a virtual environment with the repositories that we want to override.

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

## Training a model

To train a model, you need to set up a job script (call this job_script.sh):

{% highlight bash %}
#!/bin/bash
#SBATCH --output=/scratch/project_465000899/aifs/logs/insert_log_name_here.out
#SBATCH --error=/scratch/project_465000899/aifs/logs/insert_log_name_here.err
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=8
#SBATCH --account=project_465000899
#SBATCH --partition=standard-g
#SBATCH --gpus-per-node=8
#SBATCH --time=20:00:00
#
module load LUMI/22.08 partition/G
#module load singularity-bindings
module load aws-ofi-rccl

# Name and notes optional
# export WANDB_NAME="lumi"
# export WANDB_NOTES="test run on Lumi"
#
export NCCL_SOCKET_IFNAME=hsn
export NCCL_NET_GDR_LEVEL=3
export MIOPEN_USER_DB_PATH=/tmp/${USER}-miopen-cache-${SLURM_JOB_ID}
export MIOPEN_CUSTOM_CACHE_DIR=${MIOPEN_USER_DB_PATH}
export CXI_FORK_SAFE=1
export CXI_FORK_SAFE_HP=1
export FI_CXI_DISABLE_CQ_HUGETLB=1
export SINGULARITYENV_LD_LIBRARY_PATH=/opt/ompi/lib:${EBROOTAWSMINOFIMINRCCL}/lib:/opt/cray/xpmem/2.4.4-2.3_9.1__gff0e1d9.shasta/lib64:${SINGULARITYENV_LD_LIBRARY_PATH}

export HYDRA_FULL_ERROR=1
export SINGULARITY_BIND='/pfs:/pfs'

srun singularity exec -B /pfs/:/pfs/ /scratch/project_465000899/aifs/container/containers/aifs-met-benchmark-pytorch-2.0.1-rocm-6.0.0-py3.9-v.0.1.5.sif python /pfs/lustrep4/scratch/project_465000899/insert_your_path_here/ppi_train.py
{% endhighlight %}

To run the job, do this:

{% highlight bash %}
sbatch job_script.sh
{% endhighlight %}
