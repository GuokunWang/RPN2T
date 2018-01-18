function [labels] = get_label(samples, gt, output_sigma_factor)
%GET_LABEL Summary of this function goes here
%   Detailed explanation goes here
num_sample = size(samples,1);
rowDist = ones([1,num_sample]);
gt_center = repmat(gt(1:2) + gt(3:4) / 2,[num_sample,1]);
samples_center = samples(:,1:2) + samples(:,3:4) / 2;
output_sigma = repmat(sqrt(prod(gt([3,4]))) * output_sigma_factor,[num_sample,1]);
labels = cellfun(@(x,y,z) cal_label(x,y,z),mat2cell(samples_center,rowDist), mat2cell(gt_center,rowDist), mat2cell(output_sigma,rowDist),'UniformOutput',false);
labels = cell2mat(permute(labels,[2,3,1]));
labels = reshape(labels,[14,14,1,num_sample]);
end

function [label] = cal_label(samples_center, gt_center,output_sigma)
tem_x = [- 8 - 16 * 6 : 16 : 8 + 16 * 6] + (samples_center(1) - gt_center(1));
tem_y = [- 8 - 16 * 6 : 16 : 8 + 16 * 6] + (samples_center(2) - gt_center(2));
[rs,cs] = ndgrid(tem_x, tem_y);
label = exp(-0.5 * (((rs.^2 + cs.^2) / output_sigma(1)^2)));
end
