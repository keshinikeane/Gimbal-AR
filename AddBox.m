function [ fFinal ] = AddBox( fI )
%AddBox This function adds the box
% 
%% Get Frame Dimensions
[nY,nX,nZ]=size(fI);
mY = nY*0.05;
mX = mY;
iboxX = nX/3;
iboxY = nX/10;
iboxPX = nX-(mX+iboxX);
iboxPY = mY;
%% Add Graphics
fTemp1 = insertShape(fI,...                 % Adds Filled Rectangle
    'FilledRectangle',[iboxPX,iboxPY,iboxX,iboxY],...
    'LineWidth', 5,...
    'Color', 255*[0.9, 0.9, 0.9],'Opacity', 1);
fTemp2 = insertShape(fTemp1,...             % Adds Border Rectangle
    'Rectangle',[iboxPX,iboxPY,iboxX,iboxY],...
    'LineWidth', 5,...
    'Color', 255*[0.75, 0.75, 0.75],'Opacity', 1);


fFinal = fTemp2;
end

