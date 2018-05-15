function varargout = FRPN2T_GUI_Demo(varargin)
% FRPN2T_GUI_DEMO MATLAB code for FRPN2T_GUI_Demo.fig
%      FRPN2T_GUI_DEMO, by itself, creates a new FRPN2T_GUI_DEMO or raises the existing
%      singleton*.
%
%      H = FRPN2T_GUI_DEMO returns the handle to a new FRPN2T_GUI_DEMO or the handle to
%      the existing singleton*.
%
%      FRPN2T_GUI_DEMO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FRPN2T_GUI_DEMO.M with the given input arguments.
%
%      FRPN2T_GUI_DEMO('Property','Value',...) creates a new FRPN2T_GUI_DEMO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FRPN2T_GUI_Demo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FRPN2T_GUI_Demo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FRPN2T_GUI_Demo

% Last Modified by GUIDE v2.5 15-May-2018 14:56:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FRPN2T_GUI_Demo_OpeningFcn, ...
                   'gui_OutputFcn',  @FRPN2T_GUI_Demo_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FRPN2T_GUI_Demo is made visible.
function FRPN2T_GUI_Demo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FRPN2T_GUI_Demo (see VARARGIN)

% Choose default command line output for FRPN2T_GUI_Demo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes FRPN2T_GUI_Demo wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = FRPN2T_GUI_Demo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global is_open;
    is_open = true;
    [filename pathname] =uigetfile({'*.avi';'*.mp4';'*.*'},'打开视频');
    %%字符串拼接 拼装路径 以上面例子说所述 此时 srt=F:\data\1.jpg
    str=[pathname filename];
    %%打开图像
    obj = VideoReader(str);

    frame = read(obj, 1);  
    %%打开axes1的句柄 进行axes1的操作
    axes(handles.axes1);
    %%在axes1中显示 图像
    image(frame)
    axis off;
    mp= handles.axes1; 
    h=imrect;

    pos=getPosition(h);
    global_config.obj = obj;
    global_config.pos = pos;
    set(handles.axes1,'userdata',global_config);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global is_open;
    global_config = get(handles.axes1,'userdata');
    obj = global_config.obj;
    pos = global_config.pos;

    frame = read(obj, 1); 
    axes(handles.axes1);
    %image(imCp)
    image(frame);
    rectangle('Position', pos);
    %%在axes1中显示 图像
    axis off;


    addpath(genpath('./'))
    init_workspace;
    if(isempty(gcp('nocreate')))
        parpool;
    end
    global versions;
    versions = 3;
    global nets;
    nets = 1;
    lk(0);
    tld = tldInit();
    nFrames = obj.NumberOfFrame;

    img = frame;
    if(size(img,3)==1), img = cat(3,img,img,img); end
    targetLoc = pos;
    result = zeros(nFrames, 4); result(1,:) = targetLoc;

    opts = rpn2t_init(img);
    [feat_extract_net, track_net_solver] = rpn2t_init_rpn(opts);

    %% Train a bbox regressor
    if(opts.bbreg)
        pos_examples = gen_samples('uniform_aspect', targetLoc, opts.bbreg_nSamples*10, opts, 0.3, 10);
        r = overlap_ratio(pos_examples,targetLoc);
        pos_examples = pos_examples(r>0.6,:);
        pos_examples = pos_examples(randsample(end,min(opts.bbreg_nSamples,end)),:);
        feat_conv = rpn2t_features_convX_rpn(feat_extract_net, img, pos_examples, opts);

        X = permute(feat_conv,[4,3,1,2]);
        X1 = X(:,:,7:8,6:9);
        X2 = X(:,:,6:6,7:8);
        X3 = X(:,:,9:9,7:8);
        X1 = X1(:,:);
        X2 = X2(:,:);
        X3 = X3(:,:);
        X = cat(2, X1, X2, X3);
        
        bbox = pos_examples;
        bbox_gt = repmat(targetLoc,size(pos_examples,1),1);
        bbox_reg = train_bbox_regressor(X, bbox, bbox_gt);
    end

    %% Extract training examples
    fprintf('  extract features...\n');
    spf1 = tic;

    % draw positive/negative samples
    pos_examples = gen_samples('gaussian', targetLoc, opts.nPos_init*2, opts, 0.1, 5);

    r = overlap_ratio(pos_examples,targetLoc);
    pos_examples = pos_examples(r>opts.posThr_init,:);
    pos_examples = pos_examples(randsample(end,min(opts.nPos_init,end)),:);

    neg_examples = [gen_samples('uniform', targetLoc, opts.nNeg_init, opts, 1, 10);...
    gen_samples('whole', targetLoc, opts.nNeg_init, opts)];
    r = overlap_ratio(neg_examples,targetLoc);
    neg_examples = neg_examples(r<opts.negThr_init,:);
    neg_examples = neg_examples(randsample(end,min(opts.nNeg_init,end)),:);

    examples = [pos_examples; neg_examples];
    
    pos_patchJ   = tldGetPattern(rgb2gray(img),(targetLoc + [0,0,targetLoc(1:2)])',tld.model.patchsize);
    neg_patchJ   = tldGetPattern(rgb2gray(img),(neg_examples(1:50,:) + [zeros(50,2),neg_examples(1:50,1:2)])',tld.model.patchsize);
    tld.pex = [tld.pex  pos_patchJ];
    tld.nex = [tld.nex  neg_patchJ];
    pex_len = 10 * size(pos_examples,1);
    nex_len = 5 * size(neg_examples,1);
    
    pos_idx = 1:size(pos_examples,1);
    neg_idx = (1:size(neg_examples,1)) + size(pos_examples,1);

    % to bigger crops
    if(opts.crop_largegt)
        examples = loc2bigloc(examples);
    end

    % extract features    
    feat_conv = rpn2t_features_convX_rpn(feat_extract_net, img, examples, opts);
    pos_data = feat_conv(:,:,:,pos_idx);
    neg_data = feat_conv(:,:,:,neg_idx);


    %% Learning CNN
    fprintf('  training cnn...\n');
    rpn2t_finetune_hnm_rpn(track_net_solver, pos_data, neg_data, opts,opts.maxiter_init);
    
    
    total_pos_data = cell(1,1,1,nFrames);
    total_neg_data = cell(1,1,1,nFrames);

    neg_examples = gen_samples('uniform', targetLoc, opts.nNeg_update*2, opts, 2, 5);
    r = overlap_ratio(neg_examples,targetLoc);
    neg_examples = neg_examples(r<opts.negThr_init,:);
    neg_examples = neg_examples(randsample(end,min(opts.nNeg_update,end)),:);

    examples = [pos_examples; neg_examples];

    % to bigger crops
    if(opts.crop_largegt)
        examples = loc2bigloc(examples);
    end
    
    pos_idx = 1:size(pos_examples,1);
    neg_idx = (1:size(neg_examples,1)) + size(pos_examples,1);
    
    feat_conv = rpn2t_features_convX_rpn(feat_extract_net, img, examples, opts);
    total_pos_data{1} = feat_conv(:,:,:,pos_idx);
    total_neg_data{1} = feat_conv(:,:,:,neg_idx);
    total_pos_data{1} = permute(total_pos_data{1}, [1 4 3 2]);
    total_neg_data{1} = permute(total_neg_data{1}, [1 4 3 2]);

    success_frames = 1;
    trans_f = opts.trans_f;
    scale_f = opts.scale_f;
    total_time = tic;
    prev_img = rgb2gray(img);
    %% Main loop
    for To = 2:nFrames;
    
        if ~is_open
            break;
        end
        fprintf('\nProcessing frame %d/%d... \n', To, nFrames);

        img = read(obj, To);
        if(size(img,3)==1), img = cat(3,img,img,img); end

        spf = tic;
        %% Estimation
        % draw target candidates
        BB2 = rpn2t_flow_tracking(prev_img, rgb2gray(img), tld, targetLoc);        
        samples = gen_samples('gaussian', BB2, opts.nSamples, opts, trans_f, scale_f);
        %samples = gen_samples('gaussian', targetLoc, opts.nSamples, opts, trans_f, scale_f);

        % to bigger crops
        if(opts.crop_largegt)
            examples_big = loc2bigloc(samples);        
            feat_conv = rpn2t_features_convX_rpn(feat_extract_net, img, examples_big, opts);
        else
            feat_conv = rpn2t_features_convX_rpn(feat_extract_net, img, samples, opts);
        end

        % evaluate the candidates        
        feat_fc = rpn2t_features_fcX_rpn(track_net_solver, feat_conv, opts);
        

        feat_fc = feat_fc';
        [scores,idx] = sort(feat_fc,'descend');

        target_score = mean(scores(1:5));
        targetLoc = round(mean(samples(idx(1:5),:)));
        if(opts.crop_largegt)
            targetLoc_big = round(mean(examples_big(idx(1:5),:)));
        end
        
        if(To <= 50)
            score_thres = 0.2;
        else
            score_thres = 0.3;
        end

        % final target
        result(To,:) = targetLoc;

        % extend search space in case of failure
        if(target_score<score_thres)
            trans_f = min(1.5, 1.1*trans_f);
            %trans_f = min(3, 1.8*trans_f);
        else
            trans_f = opts.trans_f;
        end

        % bbox regression
        if(opts.bbreg && target_score>0)
            X_ = permute(feat_conv(:,:,:,idx(1:5)),[4,3,1,2]);
            
            X1_ = X_(:,:,7:8,6:9);
            X2_ = X_(:,:,6:6,7:8);
            X3_ = X_(:,:,9:9,7:8);
            X1_ = X1_(:,:);
            X2_ = X2_(:,:);
            X3_ = X3_(:,:);
            X_ = cat(2, X1_, X2_, X3_);
                     
            bbox_ = samples(idx(1:5),:);
            pred_boxes = predict_bbox_regressor(bbox_reg.model, X_, bbox_);
            result(To,:) = round(mean(pred_boxes,1));
        end

        %% Prepare training data
        
        if(target_score>score_thres)
            pos_examples = gen_samples('gaussian', targetLoc, opts.nPos_update*2, opts, 0.1, 5);
            r = overlap_ratio(pos_examples,targetLoc);
            pos_examples = pos_examples(r>opts.posThr_update,:);
            pos_examples = pos_examples(randsample(end,min(opts.nPos_update,end)),:);

            neg_examples = gen_samples('uniform', targetLoc, opts.nNeg_update*2, opts, 2, 5);
            r = overlap_ratio(neg_examples,targetLoc);
            neg_examples = neg_examples(r<opts.negThr_update,:);
            neg_examples = neg_examples(randsample(end,min(opts.nNeg_update,end)),:);

            examples = [pos_examples; neg_examples];
            pos_patchJ   = tldGetPattern(rgb2gray(img),(targetLoc + [0,0,targetLoc(1:2)])',tld.model.patchsize);
            neg_patchJ   = tldGetPattern(rgb2gray(img),(neg_examples + [zeros(size(neg_examples,1),2),neg_examples(:,1:2)])',tld.model.patchsize);
            tld.pex = [tld.pex, pos_patchJ];
            tld.nex = [tld.nex, neg_patchJ];
            
            % to bigger crops
            if(opts.crop_largegt)
                examples = loc2bigloc(examples);
            end            
            
            pos_idx = 1:size(pos_examples,1);
            neg_idx = (1:size(neg_examples,1)) + size(pos_examples,1);
          
            feat_conv = rpn2t_features_convX_rpn(feat_extract_net, img, examples, opts);
            total_pos_data{To} = feat_conv(:,:,:,pos_idx);
            total_neg_data{To} = feat_conv(:,:,:,neg_idx);
            total_pos_data{To} = permute(total_pos_data{To}, [1 4 3 2]);
            total_neg_data{To} = permute(total_neg_data{To}, [1 4 3 2]);

            success_frames = [success_frames, To];
            if(numel(success_frames)>opts.nFrames_long)
                total_pos_data{success_frames(end-opts.nFrames_long)} = single([]);
            end
            if(numel(success_frames)>opts.nFrames_short)
                total_neg_data{success_frames(end-opts.nFrames_short)} = single([]);
            end
            
            if(size(tld.pex,2)>pex_len)
                tld.pex(:,1:(size(tld.pex,2)-pex_len)) = [];
            end
            if(size(tld.nex,2)>nex_len)
                tld.nex(:,1:(size(tld.nex,2)-nex_len)) = [];
            end
            
        else
            total_pos_data{To} = single([]);
            total_neg_data{To} = single([]);
        end

        %% Network update
        if((mod(To,opts.update_interval)==0 || target_score<score_thres) && To~=nFrames)
            if (target_score<score_thres) % short-term update
                %pos_data = cell2mat(total_pos_data(success_frames(max(1,end-opts.nFrames_short+1):end)));
                pos_data = total_pos_data(success_frames(max(1,end-opts.nFrames_short+1):end));
                pos_data = [pos_data{:}];
                pos_data = permute(pos_data, [1 4 3 2]);
            else % long-term update
                %pos_data = cell2mat(total_pos_data(success_frames(max(1,end-opts.nFrames_long+1):end)));
                pos_data = total_pos_data(success_frames(max(1,end-opts.nFrames_long+1):end));
                pos_data = [pos_data{:}];
                pos_data = permute(pos_data, [1 4 3 2]);
            end
                %neg_data = cell2mat(total_neg_data(success_frames(max(1,end-opts.nFrames_short+1):end)));
                neg_data = total_neg_data(success_frames(max(1,end-opts.nFrames_short+1):end));
                neg_data = [neg_data{:}];
                neg_data = permute(neg_data, [1 4 3 2]);

            %fprintf();            
            rpn2t_finetune_hnm_rpn(track_net_solver,pos_data,neg_data,opts,opts.maxiter_update);
        end

        spf = toc(spf);
        fprintf('%f seconds  ',spf);

            axes(handles.axes1);
        %image(imCp)
        image(img);
        rectangle('Position', targetLoc);
        %%在axes1中显示 图像
        axis off;
        
        prev_img = rgb2gray(img);
    end

% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global is_open;
    is_open = false;
