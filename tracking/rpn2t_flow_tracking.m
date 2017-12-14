function BB2 = rpn2t_flow_tracking(prev_img, img, tld, targetLoc)
    % draw target candidates
        BB1    = (targetLoc + [0,0,targetLoc(1), targetLoc(2)])';
        xFI    = bb_points(BB1,10,10,5); % generate 10x10 grid of points within BB1 with margin 5 px
        xFJ    = lk(2,prev_img,img,xFI,xFI); % track all points by Lucas-Kanade tracker from frame I to frame J, estimate Forward-Backward error, and NCC for each point
        medFB  = median2(xFJ(3,:)); % get median of Forward-Backward error
        medNCC = median2(xFJ(4,:)); % get median for NCC
        idxF   = xFJ(3,:) <= medFB & xFJ(4,:)>= medNCC; % get indexes of reliable points
        BB2    = bb_predict(BB1,xFI(:,idxF),xFJ(1:2,idxF)); % estimate BB2 using the reliable points only
        %BB2    = [(BB2(1) + BB2(3) - targetLoc(3)) / 2,(BB2(2) + BB2(4) - targetLoc(4)) / 2, targetLoc(3), targetLoc(4)];
        
        if ~bb_isdef(BB2) || bb_isout(BB2,size(img)), BB2 = targetLoc; return; end % bounding box out of image
        if tld.control.maxbbox > 0 && medFB > 10, BB2 = targetLoc; return; end  % too unstable predictions

        % estimate confidence and validity
        patchJ   = tldGetPattern(img,BB2,tld.model.patchsize); % sample patch in current image
        [~,Conf] = tldNN(patchJ,tld); % estimate its Conservative Similarity (considering 50% of positive patches only)
        if Conf < tld.model.thr_nn_valid, BB2 = targetLoc; return; end % tracker is inside the 'core'
        BB2    = [(BB2(1) + BB2(3) - targetLoc(3)) / 2,(BB2(2) + BB2(4) - targetLoc(4)) / 2, targetLoc(3), targetLoc(4)];
        BB2(1) = max(BB2(1),1);
        BB2(1) = min(size(img,2) - BB2(3),BB2(1));
        
        BB2(2) = max(BB2(2),1);
        BB2(2) = min(size(img,1) - BB2(4),BB2(2));
end