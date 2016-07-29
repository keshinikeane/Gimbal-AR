function [ fFinal ] = AddGraphics( fI,target,message )
%AddGraphics Combination of the graphics functions
%   
  videoTemp2 = AddBox(fI);
  videoTemp3 = AddLine(videoTemp2,target);
  VideoTemp4 = AddText(videoTemp3,message);
  
  fFinal = VideoTemp4;

end

