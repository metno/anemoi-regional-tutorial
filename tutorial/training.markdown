---
layout: post
title:  "Training a model"
date:   2024-06-14 10:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
order: 4
toc: true
tags: anemoi
---

In this tutorial, we will train a data-driven model. A pre-requisite is to have set up aifs-mono environment.
The first step is to change the default configuration options in aifs-mono. we will change configuration
files located in `aifs/config/`.

## Set basic configuration options

Add the file `aifs/config/harware/paths/lumi.yaml`
{% highlight yaml %}
data: /pfs/lustrep4/scratch/project_465000899/aifs/dataset
output_base: /pfs/lustrep4/scratch/project_465000899/aifs/experiments/
output: ${hardware.paths.output_base}/
logs:
  base: ${hardware.paths.output}logs/
  wandb: ${hardware.paths.logs.base}
  tensorboard: ${hardware.paths.logs.base}/tensorboard
  #We might want to add mlflow functionality, and if so, define the path here
checkpoints: ${hardware.paths.output}checkpoints/
plots: ${hardware.paths.output}plots/
losses: ${hardware.paths.output}losses/
profiler: ${hardware.paths.output}profiler/
graph: /pfs/lustrep4/scratch/project_465000899/aifs/graphs/
{% endhighlight %}

Next, we will set the files

Connect these files: `aifs/config/hardware/lumi.yaml`
{% highlight yaml %}
defaults:
  - paths: lumi
  - files: lumi

# number of GPUs per node and number of nodes (for DDP)
num_gpus_per_node: 8
num_nodes: 4
num_gpus_per_model: 1
{% endhighlight %}

Next, we will set the files

## Set dataloader options

Add the file `aifs/config/dataloader/lumi.yaml`

## Runing the model
