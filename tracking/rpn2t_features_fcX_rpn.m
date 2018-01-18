function [ feat, feat_h] = rpn2t_features_fcX_rpn(solver, feat_init, ims, samples, targetLoc, opts)

n = size(ims,4);
nBatches = ceil(n/(opts.batchSize*2));

tic

for i=1:nBatches
    
    batch = ims(:,:,:,opts.batchSize*2*(i-1)+1:min(end,opts.batchSize*2*i));
    batch = single(batch);

    batch_p = repmat(feat_init, [1,1,1,size(batch,4) / size(feat_init, 4)]);
    batch_p = single(batch_p);
    
    label_tmp = rand(size(batch,1), size(batch,2), 1, size(batch,4));
    weight_tmp = rand(size(label_tmp));
    %net_inputs = {batch, label_tmp, weight_tmp,label_tmp,weight_tmp};
    %net_inputs = {batch, label_tmp, label_tmp};
    net_inputs = {batch, batch_p, label_tmp, label_tmp};

    % Reshape net's input blobs
    %solver.net.reshape_as_input(net_inputs);
    solver.net.blobs('data').reshape(size(batch))
    solver.net.blobs('data_p').reshape(size(batch_p))
    solver.net.blobs('labels1').reshape(size(label_tmp))
    solver.net.blobs('labels2').reshape(size(label_tmp))
    solver.net.reshape();
    solver.net.forward(net_inputs);
    res1 = solver.net.blobs('proposal_cls_prob1').get_data();
    res1 = res1(:,:,1,:);
    res2 =  solver.net.blobs('proposal_cls_prob2').get_data();
    res2 = res2(:,:,1,:);
    
    heat_map = get_label(samples, targetLoc, 1);
    sub_weight1 = opts.weight1.*opts.weight_mask1;
    sub_weight2 = opts.weight2.*opts.weight_mask2;
    
    res1_h = res1.*heat_map;
    res1_h = res1_h.*repmat(sub_weight1, [1 1 1 size(res1_h,4)]);
    res1_h = squeeze(sum(sum(res1_h))) / sum(sum(sub_weight1));
    
    res1 = res1.*repmat(sub_weight1, [1 1 1 size(res1,4)]);
    res1 = squeeze(sum(sum(res1))) / sum(sum(sub_weight1));
    
    res2_h = res2.*heat_map; 
    res2_h = res2_h.*repmat(sub_weight2, [1 1 1 size(res2_h,4)]);
    res2_h = squeeze(sum(sum(res2_h))) / sum(sum(sub_weight2));
    
    res2 = res2.*repmat(sub_weight2, [1 1 1 size(res2,4)]);
    res2 = squeeze(sum(sum(res2))) / sum(sum(sub_weight2));
    %res = (res1+res2)/2;
    res_h = 0.45*res1_h + 0.55*res2_h;
    res = 0.45*res1 + 0.55*res2;
    if ~exist('feat','var')
        feat = zeros(1,n,'single');
    end
    if ~exist('feat_h','var')
        feat_h = zeros(1,n,'single');
    end
    feat(opts.batchSize*2*(i-1)+1:min(end,opts.batchSize*2*i)) = res;
    feat_h(opts.batchSize*2*(i-1)+1:min(end,opts.batchSize*2*i)) = res_h;
    
end

spf = toc;
fprintf('time of score = %f\n',spf);
