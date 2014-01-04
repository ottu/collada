#!/bin/bash
export PATH=../../dmd2/osx/bin:$PATH

rdmd -unittest --main collada.d \
  -I../ \
  -I../adjustxml \
  -I. \
  animation.d \
  base.d \
  camera.d \
  controller.d \
  dataflow.d \
  effect.d \
  geometry.d \
  image.d \
  instance.d \
  light.d \
  material.d \
  model.d \
  scene.d \
  transform.d
