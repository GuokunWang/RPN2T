# RPN2T
Original RPN2T project paget: <br>

https://github.com/jimmy-ren/RPN2T

### Introduction
We modify the RPN2T tracker by adding flow in sampling strategy and modify the network to siamese network, the paper named **Flow Guided Siamese Network for Visual Tracking**

This software is implemented using [Caffe](https://github.com/BVLC/caffe/) and part of [Faster_rcnn](https://github.com/ShaoqingRen/faster_rcnn).

### System Requirements

This code is tested on 64 bit Linux (Ubuntu 14.04 LTS).

**Prerequisites**     
      
  0. MATLAB (tested with R2014b)  
  0. Caffe (included in this repository `external/_caffe/`)   
  0. For GPU support, a GPU, CUDA toolkit and cuDNN will be needed. We have tested in `GTX TitanX(MAXWELL)` with `CUDA7.5+cuDNNv5` and `GTX 1080` with `CUDA8.0+cuDNNv5.1`.

### Installation

  > Compile Caffe according to the [installation guideline](http://caffe.berkeleyvision.org/installation.html).  
  ```shell  
  cd $(RPN2T_ROOT)
  cd external/_caffe
  # Adjust Makefile.config (For example, the path of MATLAB.)
  make all -j8
  make matcaffe
  ```  

### Online Tracking using RPN2T

**Demo**
  > Run 'tracking/demo_tracking.m'.

### Result 

[OTB100](https://drive.google.com/open?id=1t7r2NB1EdPgzLVtKfCASDRnke9Ro9He-)