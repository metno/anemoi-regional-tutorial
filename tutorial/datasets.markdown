---
layout: post
title:  "Datasets"
date:   2024-06-14 10:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
order: 2
toc: true
tags: anemoi
---

## Downloading existing datasets

To see what datasets area already available, checkout https://anemoi.ecmwf.int/datasets (requires ECMWF login
credentials). The site provides download links to files in S3 buckets, and paths to where files are located
on LUMI and Leonardo.

## Creating your own a dataset

To create a dataset based on your own input data, you can use anemoi-datasets. This is a flexible tool for
building training-ready datasets that are optimized for aifs-mono. The full documentation for the tool is
[here](https://anemoi-datasets.readthedocs.io/en/latest/). Some good reasons to use the tool are:
- It ensures the data is compatible with aifs-mono
- It automatically computes normalization coefficients used in the training
- It supports many data-formats, including GRIB, NetCDF
- It supports many access protocols, including MARS, and OpenDAP
- It supports a number of filters that can be applied to the dataset variables (e.g. rotating winds in LAM
        models)
- It is extendable to new input formats and new filters

Install the anemoi-datasets package like this:

{% highlight bash %}
pip3 install anemoi-datasets[all]
{% endhighlight %}

This installs the `anemoi-datasets` command-line tool.

To create a dataset, you need a configuration file
(`example_config.yaml`) and an output path (`dataset.zarr/`):

{% highlight bash %}
anemoi-datasets create example_config.yaml dataset.zarr/
{% endhighlight %}

NOTE: Make sure the output name ends in zarr or zip, otherwise the tool
does not know what type of archive to create, and will fail.

Here is an example configuration file that retrieves ERA5 fields from mars
([download]({{ site.baseurl }}/assets/files/datasets/example_config.yaml )).

{% highlight yaml %}
{% include files/datasets/example_config.yaml %}
{% endhighlight %}

Once the dataset has been created, you can inspect it's content with:
{% highlight bash %}
anemoi-datasets inspect dataset.zarr
{% endhighlight %}

{% highlight bash %}
📦 Path          : dataset.zarr
🔢 Format version: 0.20.0

📅 Start      : 2024-01-01 00:00
📅 End        : 2024-01-01 18:00
⏰ Frequency  : 6h
🚫 Missing    : 0
🌎 Resolution : 1.0
🌎 Field shape: [181, 360]

📐 Shape      : 4 × 5 × 1 × 65,160 (5 MiB)
💽 Size       : 2.7 MiB (2,814,859)
📁 Files      : 36

   Index │ Variable │      Min │     Max │      Mean │    Stdev
   ──────┼──────────┼──────────┼─────────┼───────────┼─────────
       0 │ 10u      │ -24.3116 │   25.79 │ 0.0595319 │   5.5856
       1 │ 10v      │ -21.2397 │  21.851 │ -0.270924 │  4.23947
       2 │ 2t       │  214.979 │ 319.111 │   277.775 │  19.9318
       3 │ lsm      │        0 │       1 │  0.335152 │ 0.464236
       4 │ msl      │  95708.5 │  104284 │    100867 │  1452.67
   ──────┴──────────┴──────────┴─────────┴───────────┴─────────
🔋 Dataset ready, last update 2 hours ago.
📊 Statistics ready.
{% endhighlight %}

## Extending anemoi-datasets

anemoi-datasets is a powerful tool with a lot of functionality. However, you may have data in unsupported
formats, or you need to convert variables in the dataset to match those in ERA5. In this tutorial, we will
extend anemoi-datasets to create dataset for CARRA.

If you want to go down this route, you need to clone the repository

{% highlight bash %}
git clone git@github.com:ecmwf/anemoi-datasets
cd anemoi-datasets
virtualenv .venv
pip install -e .[all]
{% endhighlight %}

To add new filters, add a new python file to `src/anemoi/datasets/create/functions/filter`. To add a new
source, add a new python file to `src/anemoi/datasets/create/functions/source`.

CARRA is stored on the Climate Data Store (CDS) so we need a new source. Create the file
`src/anemoi/datasets/create/functions/source/cds.py` ([download]({{ site.baseurl }}/assets/files/datasets/cds.py )):

{% highlight python %}
{% include files/datasets/cds.py %}
{% endhighlight %}

Next, as not all variables in CARRA are the same as in ERA5, we need to convert these. One example is the fact
that CARRA stores orography, whereas in the ERA5 datasets we use geopotential height. To solve this, we define
a very specific filter that performs all transformations needed on the CARRA dataset: Ideally,
each of these transformations could be a separate filter allowing for code reuse across datasets, but to
simplify the tutorial, we use one filter. Create a file called:
`src/anemoi/datasets/create/functions/filters/carra.py` ([download]({{ site.baseurl }}/assets/files/datasets/carra.py )):

{% highlight python %}
{% include files/datasets/carra.py %}
{% endhighlight %}

Create a `carra.yaml` config file ([download]({{ site.baseurl }}/assets/files/datasets/carra.yaml )):

{% highlight yaml %}
{% include files/datasets/carra.yaml %}
{% endhighlight %}
