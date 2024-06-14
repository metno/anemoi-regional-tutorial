---
layout: post
title:  "Building datasets"
date:   2024-06-14 10:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
order: 2
tags: anemoi
---

Use anemoi-datasets to build datasets for training data-driven models. The full documentation for the tool is
[here](https://anemoi-datasets.readthedocs.io/en/latest/).

## Getting started

First, install anemoi-datasets:

{% highlight bash %}
pip3 install anemoi-datasets[all]
{% endhighlight %}

This installs the `anemoi-datasets` command-line tool.

## Creating a dataset

To create a dataset, you need a configuration file
(`config.yaml`) and an output path (`output/`):

{% highlight bash %}
anemoi-datasets create config.yaml output/
{% endhighlight %}


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
