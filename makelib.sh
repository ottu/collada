#!/bin/bash

dmd -lib -oflibCollada.a \
    collada/animation.d \
    collada/base.d \
    collada/camera.d \
    collada/collada.d \
    collada/controller.d \
    collada/dataflow.d \
    collada/effect.d \
    collada/geometry.d \
    collada/image.d \
    collada/instance.d \
    collada/light.d \
    collada/material.d \
    collada/model.d \
    collada/modelutils.d \
    collada/scene.d \
    collada/transform.d
