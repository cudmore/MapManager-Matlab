% mmPlot Class to plot from a mmMap

% Robert Cudmore
% 20171008
% robert.cudmore@gmail.com
% Map Manager website: http://www.cudmore.io/mapmanager

classdef mmPlot < handle
    properties
        theMap
    end
    
    methods (Static=true)
        function ps = plot0(theMap, ps)
            % mapPlot0 Cannonical map manager map plot of pDist versus session
            %   h = myPlot.mapPlot0(mapSegment);
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
        
            mmPlot.installSelection(theMap, fig, ps, ps.sessions, ps.val);
        end
        
        function ps = plotStat(theMap, ps, varargin)
        % Plot a map stat
        %   mmPlot.plotStat(myMap, ps, 'Norm', '%', 'NormSession', 2, 'xAxis', 'days');
        % Parameters:
        %   myMap (mmMap object) :
        %   ps (struct) : mm plot struct
        % Optional parameters
        %   'Norm' (str) : '%' | 'Abs'
        %   'NormSession' (int) : 1..myMap.numSessions
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

            mmPlot.installSelection(theMap, fig, ps, ps.(xAxisStr), ps.val);
        end
        
        function ps = plotStat2(theMap, xps, yps)
        % Plot two stats
        %   ps = mmPlot(myMap, xps, yps);
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
            ylabel([yps.stat ' ch' num2str(yps.channel)]);
            xlabel([xps.stat ' ch' num2str(xps.channel)]);

            mmPlot.installSelection(theMap, fig, yps, xps.val, yps.val);
            
        end
        
        function installSelection(theMap, fig, ps, xVal, yVal)
            % set up click selection of run
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
            set(dcm_obj,'UpdateFcn',{@mmPlot.myupdatefcn2, ps, ds});
            datacursormode on;
        end
        
        % this is callback function from mmPlot
        function txt = myupdatefcn2(empt,event_obj, ps, ds)
            % ps (struct) : plot struct
            % ds (struct) : display struct
            
            %disp('*** in myupdatefcn2')
            
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
            
        end
        
    end % methods (Static=true)

    
    methods
        
        %
        function h = plot0_old(obj, ps)
            % mapPlot0 Cannonical map manager map plot of pDist versus session
            %   h = myPlot.mapPlot0(mapSegment);
            % Parameters:
            %    mapSegment (int) : NaN for all
            
            %ps = theMap.defaultPlotStruct(); % static
            ps.stat = 'pDist';
            %ps.mapsegment = mapSegment; % set to NaN for all
            ps = obj.theMap.GetMapValues(ps);
            % plot
            fig = figure;
            h2 = plot(ps.sessions',ps.val','-k', 'HitTest', 'off');
            % h2.HitTest = 'off'; % matlab can't do this, size(h2,1)>1
            hold on;
            h = plot(ps.sessions(:),ps.val(:),'ok');
            h.UserData = ps;
            hold off;
            dcm_obj = datacursormode(fig);
            set(dcm_obj,'UpdateFcn',@myupdatefcn);
            datacursormode on;
            ylabel('Segment Position (\mum)');
            xlabel('Sessions');
        end
    
        %
        function obj = mmPlot(mmMap)
            % mmPlot Constructor
            %   myPlot = mmPlot(myMap);
            % Parameters:
            %   mmMap : a mmMap object
            obj.theMap = mmMap;
        end
        
        %
        function h = mapPlot(obj, mapSegment, stat, channel)
            % mapPlot Plot a stat versus session
            %   h = myPlot.mapPlot(mapSegment, stat, channel)
            % Parameters:
            %   mapSegment (int) : NaN for all
            %   stat (string) :
            %   channel (int) : 
            
            %todo: check stat is valid

            ps = obj.theMap.defaultPlotStruct();
            ps.stat = stat;
            ps.channel = channel;
            ps.mapsegment = mapSegment; % set to NaN for all
            ps = obj.theMap.GetMapValues(ps);
            % plot
            f = figure;
            h = plot(ps.days,ps.val,'ok', ps.days',ps.val','-k');
            ylabel(stat)
            xlabel('Sessions')
        end

        %
        function h = mapPlotNorm(obj, mapSegment, stat, channel, normSession)
            % mapPlotNorm Plot a stat normalized to normSession, x-axis is days
            %   h = myPlot.mapPlot(mapSegment, stat, channel, normSession)
            % Parameters:
            %   mapSegment (int) : NaN for all
            %   stat (string) :
            %   channel (int) : 
            %   normSession (int) : session to normalize to
            
            %todo: check stat is valid

            ps = obj.theMap.defaultPlotStruct();
            ps.stat = stat;
            ps.channel = channel;
            ps.mapsegment = mapSegment; % set to NaN for all
            ps = obj.theMap.GetMapValues(ps);

            % Tip: Change this line to normalize using absolute change, etc.
            percentChange = bsxfun(@rdivide, ps.val, ps.val(:,normSession)) * 100;

            % plot
            h = plot(ps.days, percentChange, 'ok', ps.days',percentChange','-k');
            % we lose the ' ' after Session ?
            ylabel(strcat(stat,' (% Change From Session ', num2str(normSession), ')'));
            xlabel('Days');
        end

        %
        function h = mapPlotSession(obj, mapSegment, stat, channel, xSession, ySession)
            % mapPlotSession Plot a single stat for 2 sessions
            %   h = myPlot.mapPlotSession(mapSegment, stat, channel, xSession, ySession)
            % Parameters:
            %   mapSegment (int) : NaN for all
            %   stat (string) :
            %   channel (int) : 
            %   xSession (int) : y-axis session
            %   ySession (int) : x-axis session
            
            ps = obj.theMap.defaultPlotStruct();
            ps.stat = stat;
            ps.channel = channel;
            ps.mapsegment = mapSegment; % NaN for all, otherwise one mapSegment
            ps = obj.theMap.GetMapValues(ps); % ps.val has ps.stat for all sessions
            
            % Tip: You can normalize ySession to be percent or absolute change from xSession
            
            %plot
            h = plot(ps.val(:,xSession), ps.val(:,ySession), 'ok');
            ylabel(strcat(stat,' (Session ', num2str(ySession), ')'));
            xlabel(strcat(stat,' (Session ', num2str(xSession), ')'));
        end
        
        function h = mapPlotTracing(obj, mapSegment, session)
            % mapPlotTracing Plot the segment tracing
            %   h = myPlot.mapPlotTracing(mapSegment, session)
            % Parameters:
            %   mapSegment (int) : Map segment, NaN for all
            %   session (int) : Session, NaN for all (all is not very useful)

            ps = obj.theMap.defaultPlotStruct();
            ps.mapsegment = mapSegment;
            ps.session = session;
            ps = obj.theMap.GetLine(ps);
            
            plot(ps.line(:,1), ps.line(:,2), '.k', 'MarkerSize', 25);
            ylabel('\mum')
            xlabel('\mum')
        end
        
        function h = mapPlotImage(obj, session, channel, appendAnnotations, appendLines)
            % mapPlotImage Plot a maximal intensity projection of a stack with
            % optionally overlaid annotations and lines
            %   h = myPlot.mapPlotImage(session, channel, appendAnnotation, appendLines);
            % Parameters:
            %   session (int) : 
            %   channel (int) : 
            %   appendAnnotations (boolean) :
            %   appendLines (boolean) :
            
            ps = obj.theMap.defaultPlotStruct();
            ps.session = session;
            ps.channel = channel;
            ps = obj.theMap.LoadStacks(ps); % fills in ps.image

            maxImage = max(ps.images{ps.session}, [], 3);
            maxInt = max(maxImage(:));
            imshow(maxImage, [0 maxInt]);

            % get the scale in um
            dx = obj.theMap.GetValue_NV('dx',ps.session); % um/pixel
            px = obj.theMap.GetValue_NV('px',ps.session); % pixels
            %todo: fix this, make GetValue_NV() actually return a value
            dx = str2num(dx);
            px = str2num(px);
            imageWidth = px * dx;
            imageHeight = px * dx;
            
            % RI is a 'spatial referencing object', sounds fancy
            RI = imref2d(size(maxImage));
            RI.XWorldLimits = [0 imageWidth-dx];
            RI.YWorldLimits = [0 imageHeight-dx];

            % plot the image
            imshow(maxImage, RI, [0 maxInt]);
            xlabel('\mum');
            ylabel('\mum');

            if appendAnnotations
                ps.stat = 'x'; %reusing other parameters from above
                xps = obj.theMap.GetMapValues(ps);
                ps.stat = 'y'; %reusing other parameters from above
                yps = obj.theMap.GetMapValues(ps);
                
                hold on;
                % todo: make GetMapValues return session vector if ps.session ~= nan
                plot(xps.val(:,ps.session), yps.val(:,ps.session), '.b', 'MarkerSize', 20);
            end

            if appendLines
                hold on;
                line_ps = obj.theMap.GetLine(ps);
                plot(line_ps.line(:,1), line_ps.line(:,2), '.m', 'MarkerSize', 5);
            end

            hold off;
            
        end
        
        function h = mapPlotCondition(obj, stat, channel, conditionList)
        % mapPlotCondition Plot a stat across sessions based on session condition
        %   h = myMap.mapPlotCondition(stat, channel, conditionList);
        % Parameters:
        %   stat (str) : 
        %   channel (int) : 
        %   conditionList (cell array) : List of session condition names to plot
        %       Something like {'b', 'c*', 'd'}
        
            ps = obj.theMap.defaultPlotStruct();
            ps.stat = stat;
            ps.channel = channel;
            ps = obj.theMap.GetMapValues(ps);
            
            [m,n] = size(ps.val);
            
            % refine ps.val and ps.sessions to only include sessions in
            % conditionList
            yFinal = NaN(m,n);
            xFinal = NaN(m,n);
            
            lhsCol = 1;
            tickLabels = {};
            ticks = [];
            for j = 1:obj.theMap.numSessions
                thisSessionCond = obj.theMap.GetValue_NV('condStr',j);
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
        
    end % methods
    
end % classdef mmPlot