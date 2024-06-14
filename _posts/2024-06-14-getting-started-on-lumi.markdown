---
layout: post
title:  "Getting started on LUMI"
date:   2024-06-14 10:00:00 +0200
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
This installs the `anemoi-datasets` command-line tool.

## Creating a dataset

To create a dataset, you need a configuration file
(`config.yaml`) and an output path (`output/`):



{% highlight yaml %}
dates:
  start: 2024-01-01T00:00:00Z
  end: 2024-01-01T18:00:00Z
  frequency: 6h

input:
  join:
  - mars:
      param: [2t, msl, 10u, 10v, lsm]
      levtype: sfc
      grid: [1, 1]
  - mars:
      param: [q, t, z]
      levtype: pl
      level: [50, 100]
      grid: [1, 1]
{% endhighlight %}
