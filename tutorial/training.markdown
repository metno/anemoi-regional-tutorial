---
layout: post
title:  "Training a model"
date:   2024-06-14 10:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
order: 4
toc: true
tags: anemoi
---

In this tutorial, we will train a regional Anemoi model. A pre-requisite is that you have set up aifs-mono and its
dependencies and that you have available an ERA5 O96 dataset and a MEPS 10km dataset.

## Configuration Options
The first step is to change the configuration options, which are located in
`aifs-mono/aifs/config/`. Configuration options in aifs-mono are split across files based on topic. We will
rely on a lot of these, but override specific ones. Here is a configuration file tailored to a stretched grid
model, which we will call: `config_regional.yaml`
([download]({{ site.baseurl }}/assets/files/training/config_regional.yaml)).

{% highlight yaml %}
{% include files/training/config_regional.yaml %}
{% endhighlight %}

The part under "default" loads options from . The rest overrides these.

The first part specifies the default options from the specified config files. For example, `data: zarr` loads
data options from `config/data/zarr.yaml`.

The options after the `default` section override specific options provided by default. For example, we
override the number of channels in our model to 512 (which is 1024 in the default configuration).

The options that are important for us are:
- hardware.paths.data: Base directory where datasets are stored
- hardware.paths.output: where will model checkpoints and plots be stored
- hardware.graphs

### Diagnostics

You can enable your training run to log to ML-flow by setting `enabled: True` under `mlflow`. The value you
set for `experiment_name` to create a group many of your runs. `run_name` should be something uniquely
describing one specific training run.

### Transfer learning

If you want to pre-train a model on one domain and fine-tune on another, you first need to turn off trainable
parameters by adding this to your configuration:

{% highlight yaml %}
model:
  trainable_parameters:
    data: 0
    hidden: 0
    data2hidden: 0
    hidden2data: 0
    hidden2hidden: 0 # GNN and GraphTransformer Processor only
{% endhighlight %}

## Training the model

{% highlight bash %}
aifs-train  --config-dir ./ --config-name config_regional.yaml
{% endhighlight %}
