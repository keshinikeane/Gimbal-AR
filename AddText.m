function [ fFinal ] = AddText( fI,message )
%AddText Adds text to information Box
% 
%% Get Frame Dimensions
[nY,nX,nZ]=size(fI);
mY = round(nY*0.05);
mX = round(mY);
iboxX = round(nX/3);
iboxY = round(nX/10);
iboxPX = round(nX-(iboxX+mX/2));
iboxPY = round(mY+iboxY*1/8);
iboxPYL = round(mY+iboxY*3/8);
iboxP = [iboxPX,iboxPY];
iboxPL = [iboxPX,iboxPYL];
%textP = [iboxP;iboxPL];
textP = [iboxPX,iboxPY];
box_color = 'red';

% Add Graphics
fTemp1 = insertText(fI,textP,message,...
    'FontSize',28,'BoxColor',box_color,...
    'BoxOpacity',0,'TextColor','black');


fFinal = fTemp1;
end

