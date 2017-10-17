%mmPlot  - A class to plot <a href="matlab:help mmMap">mmMap</a> annotations, tracings, and images
%
%Static methods
%   mmPlot.mapPlot0 - Cannonical map manager map plot of pDist versus session
%   mmPlot.plotStat - Plot a map stat versus session or days
%   mmPlot.plotStat2 - Plot two stats, y versus x
%   mmPlot.mapPlotCondition - Plot a stat versus sessions only for sessions in a list
%
% <a href="matlab:methods('mmPlot')">List methods</a>, <a href="matlab:properties('mmPlot')">properties</a>

% Robert Cudmore
% 20171008
% robert.cudmore@gmail.com
% Map Manager website: http://www.cudmore.io/mapmanager

classdef mmPlot < handle
    properties
        %theMap
    end
    
    methods (Static=true)
        function ps = plot0(theMap, ps)
            % plot0 - Cannonical map manager map plot of pDist versus session
            %   h = mmPlot.mapPlot0(theMap, ps);
            % Parameters:
            %    mapSegment (int) : NaN for all
            
            % get the stat values
            ps.stat = 'pDist';
            ps = theMap.GetMapValues(ps);
            
            % plot
            fig = figure;
            lines = plot(ps.sessions',ps.val','-k', 'HitTest', 'off');
            hold on;
            markers = plot(ps.sessions(:),ps.val(:),'ok', 'HitTest', 'on');
            hold off;
            xlabel('Sessions');
            ylabel('Segment Position (\mum)');
        
            mmPlot.installSelection_(theMap, fig, ps, ps.sessions, ps.val);
        end
        
        function ps = plotStat(theMap, ps, varargin)
        % plotStat - Plot a map stat versus session or days
        %   ps = mmPlot.plotStat(theMap, ps);
        % Parameters:
        %   theMap (mmMap object) :
        %   ps (struct) : mmMap plot struct
        % Optional parameters
        %   'Norm' (str) : '%' | 'Abs'
        %   'NormSession' (int) : Session to normalize to, 1..theMap.numSessions
        %   'xAxis' (str) : 'sessions' | 'days'
        
            % todo: write function to encapsulate parsing vargin
            % parse vargin
            if mod(length(varargin),2)
                err.message = 'Name and value input arguments must come in pairs.';
                err.identifier = 'parseVarArgs:wrongInputFormat';
                error(err)                
            end
            
            % parse arguments
            params = struct();
            for i = 1:2:length(varargin)
                if ischar(varargin{i})
                    params.(varargin{i}) = varargin{i+1};
                else
                    err.message = 'Name and value input arguments must come in pairs.';
                    err.identifier = 'parseVarArgs:wrongInputFormat';
                    error(err)
                end
            end
            
            % get the stat values
            ps = theMap.GetMapValues(ps);
            
            yAxisLabel = '';
            
            % normalize values
            if isfield(params,'Norm') && isfield(params,'NormSession')
                normSession = params.NormSession;
                switch params.Norm
                    case '%'
                        normStat = bsxfun(@rdivide, ps.val, ps.val(:,normSession)) * 100;
                        ps.val = normStat;
                        yAxisLabel = '(%)';
                    case 'Abs'
                        normStat = bsxfun(@minus, ps.val, ps.val(:,normSession));
                        ps.val = normStat;
                        yAxisLabel = '(Abs)';
                end
            end
            xAxisStr = 'sessions';
            if isfield(params,'xAxis')
                valid_xAxis = {'sessions', 'days'};
                if ismember(params.xAxis, valid_xAxis)
                    xAxisStr = params.xAxis;
                else
                   error(['mmError: plotStat() got bad xAxis `' params.xAxis '`.']); 
                end
            end
            
            % plot
            fig = figure;
            lines = plot(ps.(xAxisStr)', ps.val','-k', 'HitTest', 'off');
            hold on;
            markers = plot(ps.(xAxisStr)(:), ps.val(:),'ok', 'HitTest', 'on');
            hold off;
            ylabel([ps.stat ' ch' num2str(ps.channel) ' ' yAxisLabel]);
            xlabel(xAxisStr);

            mmPlot.installSelection_(theMap, fig, ps, ps.(xAxisStr), ps.val);
        end
        
        function [xps, yps] = plotStat2(theMap, xps, yps)
        % plotStat2 - Plot two stats, y versus x
        %   [xps, yps] = mmPlot.plotStat2(theMap, xps, yps);
        % Parameters:
        %   xps.session (int) :
        %   yps.session (int) :

            % get the stat values
            xps = theMap.GetMapValues(xps);
            yps = theMap.GetMapValues(yps);
            
            % plot
            fig = figure;
            %lines = plot(ps.sessions', ps.val','-k', 'HitTest', 'off');
            %hold on;
            markers = plot(xps.val(:), yps.val(:),'ok', 'HitTest', 'on');
            %hold off;
            if ~isnan(xps.session)
                xSessionStr = [' Session ' num2str(xps.session)];
            end
            if ~isnan(yps.session)
                ySessionStr = [' Session ' num2str(yps.session)];
            end
            ylabel([yps.stat ' ch' num2str(yps.channel) ySessionStr]);
            xlabel([xps.stat ' ch' num2str(xps.channel) xSessionStr]);

            mmPlot.installSelection_(theMap, fig, yps, xps.val, yps.val);
            
        end
        
        function installSelection_(theMap, fig, ps, xVal, yVal)
        % Set up click selection of run
            xRunSel = NaN(1,theMap.numSessions);
            yRunSel = NaN(1,theMap.numSessions);
            hold on;
            % selection markers
            ds.runSelMarker = plot(xRunSel, yRunSel, 'oy');
            ds.runSelMarker.HitTest = 'off';
            ds.runSelMarker.MarkerFaceColor = 'y';
            ds.runSelMarker.MarkerEdgeColor = 'y';
            % selection lines
            ds.runSelLine = plot(xRunSel, yRunSel, '-y');
            ds.runSelLine.HitTest = 'off';
            ds.runSelLine.LineWidth = 3;
            hold off;
            
            ds.xVal = xVal; %xps.val;
            ds.yVal = yVal; %yps.val;

            % set up user click interface
            %markers.UserData = ps;
            dcm_obj = datacursormode(fig);
            set(dcm_obj,'UpdateFcn',{@mmPlot.myupdatefcn2_, ps, ds});
            datacursormode on;
        end
        
        % this is callback function from mmPlot
        function txt = myupdatefcn2_(empty,event_obj, ps, ds)
            % ps (struct) : plot struct
            % ds (struct) : display struct
            
            %disp('*** in myupdatefcn2_')
            
            %pos = get(event_obj,'Position');
            %txt = {['my x: ',num2str(pos(1))],...
            %	      ['my y: ',num2str(pos(2))]};
            
            dcm_obj = datacursormode(gcf);
            info_struct = getCursorInfo(dcm_obj);
                        
            dataIndex = info_struct.DataIndex;
            
            mapName = ps.mapName;
            val = ps.val(dataIndex);
            session = ps.sessions(dataIndex);
            stackdbidx = ps.stackdbidx(dataIndex);
            runidx = mod(dataIndex,size(ps.val,1)); % mod(a,m) returns the remainder after division of a by m
            
            % visually select run
            xRun = ds.xVal(runidx,:);
            yRun = ds.yVal(runidx,:);
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
        end
    
        function h = mapPlotCondition(theMap, stat, channel, conditionList)
        % NOT WORKING
        % mapPlotCondition - Plot a stat versus sessions only for sessions in the list
        %   ps = mmPlot.mapPlotCondition(stat, channel, conditionList);
        % Parameters:
        %   stat (str) : 
        %   channel (int) : 
        %   conditionList (cell array) : List of session condition names to plot
        %       Something like {'b', 'c*', 'd'}
        
            ps = mmMap.defaultPlotStruct();
            ps.stat = stat;
            ps.channel = channel;
            ps = theMap.GetMapValues(ps);
            
            [m,n] = size(ps.val);
            
            % refine ps.val and ps.sessions to only include sessions in
            % conditionList
            yFinal = NaN(m,n);
            xFinal = NaN(m,n);
            
            lhsCol = 1;
            tickLabels = {};
            ticks = [];
            for j = 1:theMap.numSessions
                thisSessionCond = theMap.GetValue_NV('condStr',j);
                [found,foundIndex] = ismember(thisSessionCond, conditionList);
                % foundIndex tells us lhs column
                
                if found
                    xFinal(:,lhsCol) = foundIndex; %ps.sessions(:,j);
                    yFinal(:,lhsCol) = ps.val(:,j);
                    tickLabels(lhsCol) = {thisSessionCond};
                    ticks(lhsCol) = foundIndex;
                    lhsCol = lhsCol + 1;
                end
            end % j sessions
            
            h = plot(xFinal, yFinal, 'ok', xFinal', yFinal', '-k');
            xticks(ticks);
            xticklabels(tickLabels);
            xlabel('Conditions')
        end
        
    end % methods (Static=true)
    
end % classdef mmPlot