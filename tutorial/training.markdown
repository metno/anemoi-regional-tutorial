---
layout: post
title:  "Training a model"
date:   2024-06-14 10:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
order: 4
toc: true
tags: anemoi
---

We will train a global Anemoi model on LUMI, using
the anemoi-training package. The prerequisites are that you have set
up a virtual environment with the anemoi-training package and
dependencies, and have the ERA5 O96 dataset in .zarr-format.


## Structure of the anemoi-training package

To run anemoi-training from bash, execute

{% highlight bash %}
anemoi-training train --config-dir=CONFIG_DIR --config-name=CONFIG_FILE.yaml
{% endhighlight %}

where CONFIG_DIR/CONFIG_FILE.yaml is the
full path to
your config file. The config file specifies the input dataset to the
training, training parameters, model architecture, and more. It is structured
as follows:

{% highlight yaml %}
defaults:
  - data: zarr
  - dataloader: native_grid
  - diagnostics: evaluation
  - hardware: slurm
  - graph: multi_scale
  - model: gnn
  - training: default
  - override hydra/hydra_logging: disabled
  - override hydra/job_logging: disabled
  - _self_
  
# Override default settings here..
{% endhighlight %}

where each of these lines refers to a separate yaml-file inside the
anemoi-training repository. For example `data: zarr`, refers to the yaml-file
located in `anemoi-training/src/anemoi/training/config/data/zarr.yaml`. 
To overwrite one of the configs above, say for
overwriting the learning rate for training, you can add

{% highlight yaml %}
training:
  lr:
    rate: 1e-3
{% endhighlight %}

to the end of CONFIG_FILE.yaml. This overwrites the corresponding
settings from `model: gnn`.


Here is a configuration file for running training on the ERA5 dataset
on LUMI, which we will call: `example.yaml`
([download]({{ site.baseurl }}/assets/files/training/example.yaml)).

{% highlight yaml %}
{% include files/training/example.yaml %}
{% endhighlight %}

In this example, we override the files and paths (which is not
specified in the slurm.yaml).

Important options for us are:
- **hardware.paths.data**: Base directory where datasets are stored
- **hardware.paths.output**: Where will model checkpoints and other output data such as plots be stored
- **hardware.files**: This names the datasets that we will use to train with. Use `dataset` for specifying the
global dataset and `dataset_lam` for the limited area dataset.
- **hardware.files.graph**: If you have pre-computed a specific graph, specify this here. Otherwise, a new
graph will be constructed on the fly.
- **diagnostic.log.mlflow**: You can enable your training run to log to ML-flow by setting `enabled: True`.
The value you set for `experiment_name` to create a group many of your runs. `run_name` should be something
uniquely describing one specific training run.

### Transfer learning (NOT UPDATED, what to do?)

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
anemoi-training  --config-dir=./ --config-name=example.yaml
{% endhighlight %}

If you are running this in the [job script on LUMI]({{ 'getting-started-on-lumi' }}) that we looked at earlier
by following, just replace `<command_to_run>` with the aifs-train command above.
