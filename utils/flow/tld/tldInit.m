function [opt] = tldInit()

    min_win             = 24; % minimal size of the object's bounding box in the scanning grid, it may significantly influence speed of TLD, set it to minimal size of the object
    patchsize           = [15 15]; % size of normalized patch in the object detector, larger sizes increase discriminability, must be square
    fliplr              = 0; % if set to one, the model automatically learns mirrored versions of the object
    maxbbox             = 1; % fraction of evaluated bounding boxes in every frame, maxbox = 0 means detector is truned off, if you don't care about speed set it to 1
    %Do-not-change -----------------------------------------------------------

    opt.model           = struct('min_win',min_win,'patchsize',patchsize,'fliplr',fliplr,'ncc_thesame',0.95,'valid',0.5,'num_trees',10,'num_features',13,'thr_fern',0.5,'thr_nn',0.65,'thr_nn_valid',0.7);
    opt.p_par_init      = struct('num_closest',10,'num_warps',20,'noise',5,'angle',20,'shift',0.02,'scale',0.02); % synthesis of positive examples during initialization
    opt.p_par_update    = struct('num_closest',10,'num_warps',10,'noise',5,'angle',10,'shift',0.02,'scale',0.02); % synthesis of positive examples during update
    opt.n_par           = struct('overlap',0.2,'num_patches',100); % negative examples initialization/update
    opt.tracker         = struct('occlusion',10);
    opt.control         = struct('maxbbox',maxbbox,'drop_img',1,'repeat',1);
    opt.pex = [];
    opt.nex = [];

end        
