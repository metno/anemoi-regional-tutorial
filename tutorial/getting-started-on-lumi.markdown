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

AMD has built a custom images of ROCm (versions 5.4.1 up to 5.6.1), which allows us to run PyTorch on AMD
GPUs. THe images are optimized for running on LUMI and we want to use this image instead of installing the
PyTorch through a regular package manager. These images contains special
libraries that enables efficient communications between nodes and GPUs (e.g. HPE CRAY libfabric, HPE CRAY MPICH,
RCCL and aws-ofi-rccl), which uses HPE Slingshot 11 high-speed interconnect. The prebuilt images are located at:

{% highlight bash %}
/appl/local/containers/sif-images/
{% endhighlight %}

We recommend copying the relevant ROCm image to your project folder (e.g. /scratch/project_xxxxxxxxx). In
this tutorial, we will use the sif image: `lumi-rocm-rocm-5.6.1.sif`. This image does not contain the
dependencies we need for Anemoi, however we can use the tool "cotainer" to create a new image, based on the
ROCm image, with the dependencies we want. "cotainer" is available through the module system. To simplify
the building process, you can create a script called `create_container.sh`
([download]({{ site.baseurl }}/assets/files/create_container.sh)) as follows:

{% highlight bash %}
{% include files/create_container.sh %}
{% endhighlight %}

This script takes three arguments. The first is the output name of your new container. The second is the name
of the ROCm container we are basing the image of (e.g `lumi-rocm-rocm-5.6.1.sif`). The last argument is a
yaml file which lists the dependencies we want to install into the new container. The following yaml file
([download]({{ site.baseurl }}/assets/files/dependencies.yaml)) declares all the dependencies we need for
Anemoi:

{% highlight yaml%}
{% include files/dependencies.yaml %}
{% endhighlight %}
Notice if you want add more python packages you can either place it under dependencies or pip. To build the
container, run the following:

{% highlight bash %}
./create_container your_container.sif lumi-rocm-rocm-5.6.1.sif dependencies.yaml
{% endhighlight %}

This will create a container called `your_container.sif`, and takes approximately 10-12 minutes.

NOTE: In the future, as the Anemoi codebase inevitably changes and requires new dependencies (or newer
versions of existing dependencies), you will have to build a new container. The container you use has to
contain the dependencies required by the specific version of the code base that you have checked out. It is
therefore good practice to organize how you name your containers.

## Setting up Anemoi and aifs-mono

The container we created will let you create datasets, create graphs, and train models since all Anemoi and
aifs-mono dependencies are stored in the container (they were listed in the yaml file). If you are working on
adding new functionality to either aifs-mono or Anemoi pacakges, it can be a hassle to rebuild containers
everytime we change a line of code. Instead, we can create a virtual environment with the repositories that
we want to override. Packages installed in the virtual environment are loaded preferentially over the
packages in the container.

First, create a virtual environment:
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

To train a model, you need to set up a job script that loads the virtual environment and runs the container.
In this example, we will call the script `job_script.sh`([download]({{ site.baseurl }}/assets/files/job_script.sh)):

{% highlight bash %}
{% include files/job_script.sh %}
{% endhighlight %}

In order to fully utilize LUMI's hardware, we have included correct cpu binding and paths to different
compiled files. The job script will then execute a bash script called `run-pytorch.sh` (remember to add
execution premission `chmod +x run-pytorch.sh` in order to run) which includes fetching node names
and enables exports to utilize the interconnect.

`run-pytorch.sh` ([download]({{ site.baseurl }}/assets/files/run-pytorch.sh)) looks like this:
{% highlight bash %}
{% include files/run-pytorch.sh %}
{% endhighlight %}

The last line of run-pytroch.sh executes a python script that has access to all the dependencies in the
virtual environment and the container. To run the job, do this:
{% highlight bash %}
sbatch job_script.sh
{% endhighlight %}
