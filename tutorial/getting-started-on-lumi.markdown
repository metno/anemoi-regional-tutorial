---
layout: post
title:  "Getting started on LUMI"
date:   2024-06-14 09:00:00 +0200
author: Aram Farhad Salihi (arams@met.no), Even Nordhagen, and Thomas Nipen (thomasn@met.no)
order: 1
toc: true
tags: LUMI HPC containers
---

This tutorial will help you install Anemoi and submit jobs on the LUMI supercomputer. A pre-requisite is that
you have a LUMI account and are able to log in to the system with ssh. All scripts used in this tutorial are
available [here]({{ site.baseurl }}/assets/files/lumi).

## Building a container

On LUMI, singularity containers should be used in order to reduce strain on the lustre file system. The
general strategy is to build a container with all dependencies, and leave code that you frequently
edit (e.g. Anemoi and aifs-mono) in a virtual environment stored outside the container. We do this since
building a container takes a while and we don't want to rebuild it every time we change a line of python code.

AMD has built a custom images of ROCm (versions 5.4.1 up to 5.6.1), which contains drivers that allows us to
run PyTorch on AMD GPUs. The images are highly optimized for running on LUMI and contain libraries that
enables efficient communications between nodes and GPUs (e.g. HPE CRAY libfabric, HPE CRAY MPICH,
RCCL and aws-ofi-rccl), which uses HPE Slingshot 11 high-speed interconnect. On LUMI, the prebuilt images are
located in:

{% highlight bash %}
/appl/local/containers/sif-images/
{% endhighlight %}

We recommend copying the relevant ROCm image to your project folder (e.g. /scratch/project_xxxxxxxxx). In
this tutorial, we will use the sif image: `lumi-rocm-rocm-5.6.1.sif`.

We will use this image as a starting point and expand it by adding the dependencies we need for Anemoi. To do
this, we will use the "cotainer" tool, which is available through the module system. To simplify the building
process, you can create a script called `create_container.sh` ([download]({{ site.baseurl
}}/assets/files/lumi/create_container.sh)) as follows:

{% highlight bash %}
{% include files/lumi/create_container.sh %}
{% endhighlight %}

This script takes three arguments. The first is the output name of your new container. The second is the name
of the ROCm container we are basing the image on (e.g `lumi-rocm-rocm-5.6.1.sif`). The last argument is a
yaml file which lists the dependencies we want to install into the new container. The following yaml file
([download]({{ site.baseurl }}/assets/files/lumi/dependencies.yaml)) is a working combination of dependencies
for regional modelling on LUMI:

{% highlight yaml%}
{% include files/lumi/dependencies.yaml %}
{% endhighlight %}

NOTE: In the pip dependencies, we specify specific versions of anemoi-datasets and anemoi-models that include
code needed for regional modelling. anemoi-datasets contains a fix neeed when doing transfer learning and
anemoi-models contains a fix for PyTorch version. The code will eventually be merged into the anemoi-models.

To build the container, run the following:

{% highlight bash %}
bash ./create_container.sh anemoi_container.sif lumi-rocm-rocm-5.6.1.sif dependencies.yaml
{% endhighlight %}

This will create a container called `anemoi_container.sif`, and takes approximately 10-12 minutes.

NOTE: In the future, as the Anemoi codebase inevitably changes and requires new dependencies (or newer
versions of existing dependencies), you will have to build a new container. The container you use must
contain the dependencies required by the specific version of the code base that you have checked out. It is
therefore good practice to devise a naming scheme for your containers.

## Setting up a virtual environent

We did not include aifs-mono in the container above. This is because you will likely work a lot with this
repository when configuring your training runs. Since it is a hassle to rebuild containers everytime we change
a line of code, we will instead create a virtual environment with aifs-mono in it that is stored as regular
files on the lustre file system.

We can similarily install other pacakges into the virtual environment that we want to change, such as
anemoi-datasets. Packages installed in the virtual environment will be loaded preferentially over the packages
in the container if they exist in both places.

To build the virtual environment, we will use the `virtualenv` tool provided by the Python installation inside
the container. We recommend using the container to set up the virtual envionrment and the packages to ensure that
the packages for the right Python version are installed (there is no guarantee that the Python version in the
container is also available through the module system om LUMI).

First, enter a shell inside the container:
{% highlight bash %}
singularity exec anemoi_container.sif bash
{% endhighlight %}

By default, singularity mounts your home directory, which allows you to modify the filesystem on the outside
from within the container. Create an environment, and clone and install any repository you want:

{% highlight bash %}
mkdir work
cd work
virtualenv .venv

source .venv/bin/activate
git clone git@github.com:ecmwf-lab/aifs-mono@hackathon
pip install --no-deps -e aifs-mono/
{% endhighlight %}

You can exit the singularity container by running the command `exit`.

NOTE: aifs-mono has been installed in editable mode, which means that if you change the code within the
repository, the code will be in use immediately next time you run the code.

Optional: If you wanted to install anemoi-datasets (or any other repository) into the virtual environment, you would do this:

{% highlight bash %}
git clone git@github.com:ecmwf/anemoi-datasets
pip install --no-deps -e anemoi-datasets/
{% endhighlight %}

Or you could install a repository directly, without cloning the repository (even a specific branch):
{% highlight bash %}
pip install git+https://github.com/ecmwf/anemoi-datasets.git@some_feature_branch
{% endhighlight %}

To remove the installation of anemoi-datasets from the virtual environment, just do this:
{% highlight bash %}
pip uninstall anemoi-datasets
{% endhighlight %}

If you have lost track where a package is loaded from, just do this:
{% highlight bash %}
pip freeze | anemoi-datasets
{% endhighlight %}

## Setting up a job script

To run a job in LUMI (such as training a model), you need to set up a job script that sets the virtual
environment and runs the container.
Look at the full [LUMI documentation](https://lumi-supercomputer.github.io/LUMI-EasyBuild-docs/p/PyTorch/) for
more information.
In this example, we will call the script `job_script.sh`([download]({{ site.baseurl }}/assets/files/lumi/job_script.sh)):

{% highlight bash %}
{% include files/lumi/job_script.sh %}
{% endhighlight %}

You need to tailor the script to your needs:
- Adjust the SBATCH directives are correct (e.g. fill in your project number)
- Set the VIRTUAL_ENV variable to the virtual environent (e.g. the .venv directory in the previous section)
- Set the full path to your singularity container
- Set the command you want to run inside the container

If you want to test that everything is set up correctly, you could use the following script ([download]({{ site.baseurl }}/assets/files/lumi/example.py)) and set `<command>` to `python example.py` in job_script.py:

{% highlight python %}
{% include files/lumi/example.py %}
{% endhighlight %}

To schedule the job, do this:
{% highlight bash %}
sbatch job_script.sh
{% endhighlight %}

When the job is finished, the SLURM log files should show each print statement 8 times (once from each of the
8 tasks).
