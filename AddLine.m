function [ fFinal ] = AddLine( fI,target )
%AddLine Adds the line from the Box to the target
%   
%% Get Frame Dimensions
[nY,nX,nZ]=size(fI);
mY = nY*0.05;
mX = mY;
iboxX = nX/3;
iboxY = nX/10;
iboxPX = nX-(mX+iboxX);
iboxPY = mY+iboxY/2;
iboxP = [iboxPX,iboxPY];

%% Add Graphics

fTemp1 = insertMarker(fI,target,'+','color','white','size',10);
fTemp2 = insertShape(fTemp1,'line',[target,iboxP],...
    'color',255*[0.75, 0.75, 0.75],'linewidth' ,3,'Opacity', 1);


fFinal = fTemp2;
end

