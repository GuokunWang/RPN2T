
clear;

addpath utils/
addpath utils/rpn/
addpath tracking/
addpath external/_caffe/matlab/
addpath(genpath('.'));

if(isempty(gcp('nocreate')))
    parpool;
end

%% 
%1 original rpn
%2 simplified 1 pooling 1 norm
%3 simplified 0 pooling 1 norm
%4 0 pooling 1 norm 
global versions;

versions = 3;

%net 1 ZF
%net 2 VGG
global nets;
nets = 1;

%%
%root_dir = '/data1/gkwang/dataset/vot2016/';
root_dir = '/data1/gkwang/dataset/OTB/OTB100/';
sub_dirs = dir(root_dir);
total = length(sub_dirs);
videos = {};
for i = 3:total
    if not(sub_dirs(i).isdir)
        continue;
    end
    switch(sub_dirs(i).name)
        case {'Jogging'}
             videos = [videos;'Jogging-1';'Jogging-2'];
        case {'Skating2', 'Skating2'}
             videos = [videos;'Skating2-1';'Skating2-2'];
        otherwise
            videos = [videos;sub_dirs(i).name];
    end
end
for i = 1 : length(videos)

  video = videos{i};
  clc
  %%

  %conf = genConfig('vot2016',video);
  conf = genConfig('otb',video);
  
  result = rpn2t_run_rpn(video,conf.imgList, conf.gt(1,:),false);
end
