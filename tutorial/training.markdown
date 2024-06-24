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

The first part specifies the default options from the specified config files. For example, `data: zarr` loads
data options from `aifs-mono/aifs/config/data/zarr.yaml`.

The options after the `defaults` section override specific options provided by default. For example, we
override the number of gpus per node to 8 (which is 1 in the default atos configuration that we loaded for
hardware).

The options that are important for us are:
- **hardware.num_gpus_per_node**: Set this to 8 on LUMI (as there are 8 GPU partitions per node). Other compute
- **hardware.num_gpus_per_model**: This specifies model paralellism. When running large models on many nodes,
    consider increasing this. Clusters might have a different value.
- **hardware.paths.data**: Base directory where datasets are stored
- **hardware.paths.output**: Where will model checkpoints and other output data such as plots be stored
- **hardware.files**: This names the datasets that we will use to train with. Use `dataset` for specifying the
global dataset and `dataset_lam` for the limited area dataset.
- **hardware.files.graph**: If you have pre-computed a specific graph, specify this here. Otherwise, a new
graph will be constructed on the fly.
- **diagnostic.log.mlflow**: You can enable your training run to log to ML-flow by setting `enabled: True`.
The value you set for `experiment_name` to create a group many of your runs. `run_name` should be something
uniquely describing one specific training run.

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

Your first training run will not use stretched grid, and will only use the ERA5 dataset. You need to change
the dataloader section like this:
{% highlight yaml %}
dataloader:
    dataset: ${hardware.paths.data}/${hardware.files.dataset}
{% endhighlight %}

Also:
- set `graphs: default` in the `defaults`section at the top (we don't want a stretched grid graph)
- remove `dataset_lam` in `hardware: files`.
- set `drop_vars: [list of variables not available in LAM dataset]` to all datasets. This ensures that you
- set `sort_vars: True` on all datasets.
don't pre-train a model based on variables that will not be available when fine-tuning on a LAM model.

## Training the model

Finally we can train a regional model! Run this:

{% highlight bash %}
aifs-train  --config-dir ./ --config-name config_regional.yaml
{% endhighlight %}

If you are running this in the [job script on LUMI]({{ 'getting-started-on-lumi' }}) that we looked at earlier
by following, just replace `<command_to_run>` with the aifs-train command above.
