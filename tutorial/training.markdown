---
layout: post
title:  "Training a model"
date:   2024-06-14 10:00:00 +0200
author: Thomas Nipen (thomasn@met.no)
order: 4
toc: true
tags: anemoi
---

In this tutorial, we will train an Anemoi model. A pre-requisite is that you have set up aifs-mono and its
dependencies. The first step is to change the configuration options, which are located in `aifs/config/`.

## Set basic configuration options

First, we will create a configuration file specifying the paths specific to our system. Here is an example we
have used on LUMI. Add the file `aifs/config/harware/paths/lumi.yaml`([download]({{ site.baseurl }}/assets/files/training/lumi.yaml )).

{% highlight yaml %}
{% include files/training/lumi.yaml %}
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

## Running the model
