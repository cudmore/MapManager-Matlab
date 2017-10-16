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

function txt = myupdatefcn(empt,event_obj)
% Customizes text of data tips

disp('*** in myupdatefcn')

pos = get(event_obj,'Position');
txt = {['my x: ',num2str(pos(1))],...
	      ['my y: ',num2str(pos(2))]};

% my code from function pbcb
dcm_obj = datacursormode(gcf); 
info_struct = getCursorInfo(dcm_obj);

%set(info_struct.Target,'LineWidth',2) 

%todo: add ySession and yStackdbIdx to all ps
runidx = NaN;
val = info_struct.Target.UserData.val(info_struct.DataIndex);
session = info_struct.Target.UserData.sessions(info_struct.DataIndex);
stackdbidx = info_struct.Target.UserData.stackdbidx(info_struct.DataIndex);
disp(['val:' num2str(val) ' runidx:' num2str(runidx) ' session:', num2str(session) ' stackdbidx:', num2str(stackdbidx)])
