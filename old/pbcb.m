% datacursormode on
% uicontrol('Style', 'pushbutton','Callback',@pbcb)

function pbcb(hObj,event)
['in xxx']

dcm_obj = datacursormode(gcf); 
info_struct = getCursorInfo(dcm_obj); 
title(info_struct.DataIndex);

info_struct