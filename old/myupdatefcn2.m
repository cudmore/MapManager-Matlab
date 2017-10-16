% function doc_datacursormode
% % Plots graph and sets up a custom data tip update function
% fig = figure;
% a = -16; t = 0:60;
% plot(t,sin(a*t))
%
% dcm_obj = datacursormode(fig);
% set(dcm_obj,'UpdateFcn',@myupdatefcn)
% datacursormode on
%
% install ps into fig
% fig.UserData = ps

function txt = myupdatefcn2(empt,event_obj, ps, ds)
% ps (struct) : plot struct
% ds (struct) : display struct

disp('*** in myupdatefcn2')

%pos = get(event_obj,'Position');
%txt = {['my x: ',num2str(pos(1))],...
%	      ['my y: ',num2str(pos(2))]};

% my code from function pbcb
dcm_obj = datacursormode(gcf); 
info_struct = getCursorInfo(dcm_obj);

%set(info_struct.Target,'LineWidth',2) 

dataIndex = info_struct.DataIndex;

mapName = ps.mapName;
val = ps.val(dataIndex);
session = ps.sessions(dataIndex);
stackdbidx = ps.stackdbidx(dataIndex);
runidx = mod(dataIndex,size(ps.val,1)); % mod(a,m) returns the remainder after division of a by m

% visually select run
%numSessions = size(ps.sessions,2);
%xRun = 
xRun = ds.xVal(runidx,:);
yRun = ds.yVal(runidx,:);
%set(runSel,'XData', xRun, 'YData',yRun);
ds.runSelMarker.XData = xRun;
ds.runSelMarker.YData = yRun;
ds.runSelLine.XData = xRun;
ds.runSelLine.YData = yRun;

disp(['map:' mapName ' val:' num2str(val) ...
    ' runidx:' num2str(runidx) ' session:', num2str(session) ...
    ' stackdbidx:', num2str(stackdbidx)]);

txt = {['map:', mapName], ...
    ['val:', num2str(val)], ...
    ['session:', num2str(session)], ...
    ['stackidx:', num2str(stackdbidx)]};

