function arcode2()
clear all; close all; clc;

% Reference image features
ref_image = imread('qrref.PNG');
ref_gray = rgb2gray(ref_image);
refpts = detectSURFFeatures(ref_gray);
reffeat = extractFeatures(ref_gray,refpts);

% Draw red frame
redframe = zeros(100,100,3,'uint8');
redframe(:,:,1) = 255;
redframe(3:97,3:97,1) = 0;
vid = redframe;

% Set up webcam
camera = webcam('logitech HD Pro webcam C920');
frame_width = 640; frame_height = 480;



%% GUI
% Set up video player
[videoPlayer, hAxes] = createFigureAndAxes(frame_width,frame_height);
insertButtons(videoPlayer, hAxes, camera);
playCallback(findobj('tag','PBButton123'),[],camera,hAxes);

% Create figure
function [videoPlayer, hAxes] = createFigureAndAxes(frame_width, frame_height)
    % Close figure opened by last run
    figTag = 'CVST_VideoOnAxis_9804532';
    close(findobj('tag',figTag));
 
    % Create new figure
    videoPlayer = figure('numbertitle', 'off', ...
           'name', 'QR Code Position Detector', ...
           'menubar','none', ...
           'toolbar','none', ...
           'resize', 'on', ...
           'tag',figTag, ...
           'renderer','painters', ...
           'position',[300 300 frame_width*1.3 frame_height*1.3]);
 
    % Create axes and titles
    hAxes.axis1 = createPanelAxisTitle(videoPlayer,[0 0 1 1]); % [X Y W H]
end


% Create axis
 function hAxis = createPanelAxisTitle(hFig, pos)
    % Create panel
    hPanel = uipanel('parent',hFig,'Position',pos,'Units','Normalized');

    % Create axis
    hAxis = axes('position',[0 0 1 1],'Parent',hPanel);
    hAxis.XTick = [];
    hAxis.YTick = [];
    hAxis.XColor = [1 1 1];
    hAxis.YColor = [1 1 1];
 end


% Insert buttons
function insertButtons(hFig,hAxes,camera)

    % Play button with text Start/Pause/Continue
    uicontrol(hFig,'unit','pixel','style','pushbutton','string','Start',...
            'position',[10 10 75 25], 'tag','PBButton123','callback',...
            {@playCallback,camera,hAxes});

    % Exit button with text Exit
    uicontrol(hFig,'unit','pixel','style','pushbutton','string','Exit',...
            'position',[100 10 50 25],'callback', ...
            {@exitCallback,camera,hFig});
end


% Callback
function playCallback(hObject,~,camera,hAxes)
   try
        % Check the status of play button
        isTextStart = strcmp(hObject.String,'Start');
        isTextCont  = strcmp(hObject.String,'Continue');
        if (isTextStart || isTextCont)
            hObject.String = 'Pause';
        else
            hObject.String = 'Continue';
        end

        % frames on figure
        while strcmp(hObject.String, 'Pause')
            % Get input video frame
            frame = getAndProcessFrame(camera);
            % Display input video frame on axis
            showFrameOnAxis(hAxes.axis1, frame);
        end

        % When video reaches the end of file, display "Start" on the
        % play button.
   catch ME
       % Re-throw error message if it is not related to invalid handle
       if ~strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
           rethrow(ME);
       end
   end
end




%% Image Processing
function [frame] = getAndProcessFrame(camera)
    % Camera frame features
    camfrm = snapshot(camera);
    camfrmg = rgb2gray(camfrm);
    campts = detectSURFFeatures(camfrmg);
    %imshow(camfrm), hold on;
    %plot(campts.selectStrongest(100));

    % match ref image and camera frame
    camfeat = extractFeatures(camfrmg, campts);
    idxPairs = matchFeatures(camfeat, reffeat);

    % store matched surfs
    matchedcam = campts(idxPairs(:,1));
    matchedref = refpts(idxPairs(:,2));
    %showMatchedFeatures(camfrm, ref_image, matchedcam, matchedref, 'Montage');

    % transform between ref and cam
    [reftrans,inrefpts, incampts] = estimateGeometricTransform(matchedref, matchedcam, 'Similarity');
    % show inliers of the geometric transform
    %showMatchedFeatures(camfrm, ref_image, incampts, inrefpts);
    
    % rescale video
    vidfrm = redframe;

    % get replacement and ref dimensions
    repdims = size(vidfrm(:,:,1));
    refdims = size(ref_image);
    refdims = refdims(1:2);

    % Find transform to scale video frame to image size preserving aspect ratio
    rx = refdims(1)/repdims(1);
    ry = refdims(2)/repdims(2);
    scaletransform = affine2d([ry 0 0; 0 rx 0; 0 0 1]);
    outview = imref2d(size(ref_image));
    vidfrms = imwarp(vidfrm, scaletransform,'OutputView',outview);
    %figure(1)
    %imshowpair(ref_image,vidfrms, 'Montage');

    % Apply estimated transform
    outview = imref2d(size(camfrm));
    vidfrmtrans = imwarp(vidfrms, reftrans,'OutputView',outview);
    %figure(1)
    %imshowpair(camfrm,vidfrmtrans,'Montage');

    % Insert transformed video frame into webcam frame
    alphablender = vision.AlphaBlender('Operation','Binary mask','MaskSource','Input Port');
    mask = vidfrmtrans(:,:,1)|...
           vidfrmtrans(:,:,2)|...
           vidfrmtrans(:,:,3) > 0;

    outframe = step(alphablender, camfrm,vidfrmtrans,mask);
    %figure(1)
    %imshow(outframe);


    %% Initialize point tracker

    pttracker = vision.PointTracker('MaxBidirectionalError',2);
    initialize(pttracker, incampts.Location,camfrm);
    %display the points being used
    tmarks = insertMarker(camfrm,incampts.Location,'size',7,'Color','yellow');
    %figure(1)
    %imshow(tmarks);

    % Track points frame to frame
    % store previous frame
    prevcamfrm = camfrm;
    %new frame
    camfrm = snapshot(camera);

    %find new tracked points
    [trackedpts, isvalid] = step(pttracker, camfrm);

    % only reliable data
    newvalidlocs = trackedpts(isvalid,:);
    oldvalidlocs = incampts.Location(isvalid,:);

    % estimate transform between frames
    if (nnz(isvalid) >=2)
        [trktrans, oldinloc, newinloc] = ...
            estimateGeometricTransform(oldvalidlocs, newvalidlocs,'Similarity');
    end
    % show transform
    %figure(1)
    %showMatchedFeatures(prevcamfrm,camfrm,oldinloc,newinloc,'Montage');
    % reset point tracker for next frame
    setPoints(pttracker, newvalidlocs);

    % accumulate transform from ref to cuttent frame
    trktrans.T = reftrans.T * trktrans.T; 

    % rescale new video frame
    repfrm = vid;
    outview = imref2d(size(ref_image));
    vidfrms = imwarp(vidfrm,scaletransform,'OutputView',outview);
    %figure(1);
    %imshowpair(ref_image,vidfrms,'Montage');

    % Apply total transform to new replacement video frame
    outview = imref2d(size(camfrm));
    vidfrmtrans = imwarp(vidfrms,trktrans,'OutputView', outview);
    %figure (1)
    %imshowpair(camfrm, vidfrmtrans,'Montage');

    % Insert replacement frame into webcam input
    mask = vidfrmtrans(:,:,1) |...
           vidfrmtrans(:,:,2) |...
           vidfrmtrans(:,:,3) > 0 ;
    outfrm = step(alphablender, camfrm, vidfrmtrans, mask);

    % Find center of image
    BW = im2bw(vidfrmtrans,0.1);
    BW = imfill(BW,'holes');
    st = regionprops(BW,'Centroid');
    target = st.Centroid;   
    
    % Add graphics 
    messageX = ['X: ' num2str(round(target(1)))];
    messageY = [' Y: ' num2str(round(target(2)))];
    message = [messageX,messageY];
    
    VideoFinal = AddGraphics(outfrm,target,message);
    frame = VideoFinal;
   
end

%% Exit
function exitCallback(~,~,camera,hFig)
        % Final clean up
        % Close the camera
        delete(camera);
        % Close the figure window
        close(hFig);
end
end



