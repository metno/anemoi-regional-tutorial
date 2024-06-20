---
layout: post
title:  "Getting started on LUMI"
date:   2024-06-14 09:00:00 +0200
author: Aram Farhad Salihi (arams@met.no), Even Nordhagen, and Thomas Nipen (thomasn@met.no)
order: 1
toc: true
tags: LUMI HPC containers
---

A pre-requisite for this tutorial is that you have a LUMI-G account and are able to log in to the system with ssh.

## Building a container

On LUMI, containers should be used in order to reduce strain on the lustre file system. The general strategy
is to build a singularity container with all dependencies, and leave code that you frequently edit (e.g.
Anemoi and aifs-mono) in a virtual environment stored outside the container. We do this since building a
container takes a while and we don't want to rebuild it every time we change a line of python code.

AMD has built a custom images of ROCm (versions 5.4.1 up to 5.6.1), which contains drivers that allows us to
run PyTorch on AMD GPUs. The images are highly optimized for running on LUMI and contain libraries that
enables efficient communications between nodes and GPUs (e.g. HPE CRAY libfabric, HPE CRAY MPICH,
RCCL and aws-ofi-rccl), which uses HPE Slingshot 11 high-speed interconnect. The prebuilt images are located
at:

{% highlight bash %}
/appl/local/containers/sif-images/
{% endhighlight %}

We recommend copying the relevant ROCm image to your project folder (e.g. /scratch/project_xxxxxxxxx). In
this tutorial, we will use the sif image: `lumi-rocm-rocm-5.6.1.sif`.

We will use this image as a starting point and expand it by adding the dependencies we need for Anemoi. To do
this, we will use the "cotainer" tool, which is available through the module system. To simplify the building
process, you can create a script called `create_container.sh` ([download]({{ site.baseurl
}}/assets/files/create_container.sh)) as follows:

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

If you want add more python packages you can either place it under dependencies (for packages available in
conda) or pip. To build the container, run the following:

{% highlight bash %}
./create_container your_container.sif lumi-rocm-rocm-5.6.1.sif dependencies.yaml
{% endhighlight %}

This will create a container called `your_container.sif`, and takes approximately 10-12 minutes.

NOTE: In the future, as the Anemoi codebase inevitably changes and requires new dependencies (or newer
versions of existing dependencies), you will have to build a new container. The container you use must
contain the dependencies required by the specific version of the code base that you have checked out. It is
therefore good practice to organize how you name your containers.

## Setting up Anemoi and aifs-mono

The container we created will let you create datasets, create graphs, and train models since all Anemoi and
aifs-mono dependencies are stored in the container (they were listed in the yaml file). If you are working on
adding new functionality to either aifs-mono or Anemoi pacakges, it can be a hassle to rebuild containers
everytime we change a line of code. Instead, we can create a virtual environment with the repositories that
we want to override. Packages installed in the virtual environment are loaded preferentially over the
packages in the container.

We recommend using the container to install the dependencies into the virtual environment. This ensures that
the packages for the right Python version are installed (there is no guarantee that the Python version in the
container is also available through the module system om LUMI).

First, enter a shell inside the container:
{% highlight bash %}
singularity exec <your_container>.sif bash
{% endhighlight %}

Then create a virtual environment, and clone and install the repositories we want:

{% highlight bash %}
mkdir work
cd work
virtualenv .venv

source .venv/bin/activate
git clone git@github.com:ecmwf-lab/aifs-mono
git clone git@github.com:ecmwf/anemoi-datasets
pip install -e aifs-mono/
pip install -e anemoi-datasets/
{% endhighlight %}

You can exit the singularity container by running the command `exit`.

NOTE: These repositories have been installed in editable mode, which means that if you change the code within
the repositories, the code will be use immediately when referring to them in the virtual environment.

## Setting up a job script

To train a model, you need to set up a job script that loads the virtual environment and runs the container.
Look at the full [LUMI documentation](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/p/PyTorch/) for more information.
In this example, we will call the script `job_script.sh`([download]({{ site.baseurl }}/assets/files/job_script.sh)):

{% highlight bash %}
{% include files/job_script.sh %}
{% endhighlight %}

You need to tailor the script to your needs:
- Adjust the SBATCH directives are correct (e.g. fill in your project number)
- Set the PYTHONUSERBASE to the virtual environent (e.g. the .venv directory in the previous section)
- Set the full path to your singularity container
- Set the full path to the script you want to run

If you want to test that everything is set up correctly, you could use the following script ([download]({{ site.baseurl }}/assets/files/example.py)) and call it in the job script:

{% highlight python %}
{% include files/example.py %}
{% endhighlight %}

To schedule the job, do this:
{% highlight bash %}
sbatch job_script.sh
{% endhighlight %}
