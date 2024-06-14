---
layout: post
title:  "Getting started on LUMI"
date:   2024-06-14 09:00:00 +0200
author: Aram Farhad Salihi, Even Nordhagen, and Thomas Nipen (thomasn@met.no)
tags: LUMI HPC containers
---

A pre-requisite for this tutorial is that you have a LUMI-G account and are able to log in to the system with ssh.

## Building a container

On LUMI, containers should be used in order to reduce strain onf the lustre file system. The general strategy
is to build a singularity container with all dependencies, and leave code that you frequently edit (e.g.
Anemoi and aifs-mono) in a virtual environment outside the container. We do this since building a
container takes a while and we don't want to wait for this every time we change a line of python code.

AMD has build a custom version of PyTorch that is optimized for LUMI. We want to use this for optimal
performance instead of installing the dependency. To build the singularity container, we will use cotainer,
which allows us to bundle the pre-built PyTorch version with the other dependencies we need from
pip. Create a cotainer recipe file:

{% highlight yaml %}
requirements:
   numpy
   anemoi-datasets
   mode stuff
{% endhighlight %}

To build the container, run the following:

{% highlight bash %}
build ...
{% endhighlight %}

This will create a container called `name_of_file.sif`.

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

To train a model, you need to set up a job script that loads the virtual environment and runs the container. In this example, we will call the script `job_script.sh)`:

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

module load LUMI/22.08 partition/G
#module load singularity-bindings
module load aws-ofi-rccl

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

srun singularity exec -B /pfs/:/pfs/ <full_path_to_container>.sif python <full_path_to_job_script>.py
{% endhighlight %}

To run the job, do this:

{% highlight bash %}
sbatch job_script.sh
{% endhighlight %}
