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
dependencies.

## Creating a configuration
The first step is to change the configuration options, which are located in
`aifs-mono/aifs/config/`. Configuration options in aifs-mono are split across files based on topic. We will
rely on a lot of these, but override specific ones. Here is a configuration file tailored to a stretched grid
model, which we will call: `config_regional.yaml`
([download]({{ site.baseurl }}/assets/files/training/config_regional.yaml)):

{% highlight yaml %}
{% include files/training/config_regional.yaml %}
{% endhighlight %}

The part under "default" loads options from . The rest overrides these.

The options that are important for us are:
- hardware.paths.data: Base directory where datasets are stored
- hardware.paths.output: where will model checkpoints and plots be stored
- hardware.graphs

## Training the model

{% highlight bash %}
aifs-train  --config-dir ./ --config-name config_regional.yaml
{% endhighlight %}
