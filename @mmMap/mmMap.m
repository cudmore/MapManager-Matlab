%mmMap - A class to load, extract, and analyze annotations in a Map Manager map.
%
%To construct a mmMap object:
%    myMap = mmMap(mapPath)
%
%To get a default plot struct
%    ps = mmMap.defaultPlotStruct()
%
%mmMap Properties:
%    mapName - Name of the map, same as enclosing folder name
%    mapPath - Path to map folder used in constructor
%    numChannels - Number of color channels in each stack
%    numSessions - Number of sessions in the map
%    numMapSegments - Number of segments in the map
%    mapNV -  Text table of map, rows are labelled with names, columns are sessions
%    stacks - Array of <a href="matlab:help mmStack">mmStack</a>
%
%Extract Annotations:
%    GetMapValues(ps) - Get values of annotations from a map
%    GetMapDynamics(ps) - Get the dynamics (add, subtract, etc.) of each annotation.
%
%Utility:
%    find(stat, findStr) - find annotations with notes, errors, and warnings
%    GetValue_NV(name, session) - Get value from a session in a map
%    getValidStats() - Return a cell array of valid stat names
%    isValidStat(stat) - Check if a stat is valid
%
%Add new annotations:
%    addUserStat(newStatName,newStatValues) - Add a new stat to a map
%    save() - Save user stats. Please see help for important information.
%
%Plotting:
%    plot0 - Plot a canonical map manager map of spine position versus session.
%    plotStat - Plot values of a stat versus sessions or days.
%    plotStat2 - Plot a stat (or two different stat) for two different session.
%    plotMaxProject - Plot the maximal intensity projection of a stack overlaid with tracing and annotations.
%
% <a href="matlab:methods('mmMap')">List methods</a>, <a href="matlab:properties('mmMap')">properties</a>

% Author: Robert Cudmore
% Date: 20170927
% Email: robert.cudmore@gmail.com
% Website: http://www.cudmore.io/mapmanager

% todo: add get/set function for properties (mapName, mapPath, numChannels, numSessions etc.)
% todo: write disp() function to pretty print this class with headers for
% (properties, methods, plot methods)
% todo: write fn to return map stats for a ps (per session)
% todo: [done] fn to return segment line (x,y,z)
% todo: [done] fn to return image
% todo: fn to return nearest-neighbor, ps.val=stat, ps.nnVal = nn stat ([i][j] in
% ps.val is 'spine', [i][j] in ps.nnVal is nn (value).
% todo: [done] return map nv (days, hours, etc) for plotting. add example
% todo: Add ps.stipEmptyRows and have GetMapValues() strip rows
%   based on final ps.stackdbIdx
% todo: [done] Switch ps.y and ps.x to (ps.val, ps.sessions, ps.stackdbIdx)

classdef mmMap < handle
 
    %% Public properties
    properties
        mapName = ''; % Name of the map, same as enclosing folder name
        mapPath = ''; % Path to map folder used in constructor

        numChannels % Number of color channels in each stack
        numSessions % Number of sessions in the map
        numMapSegments % Number of segments in the map
        
        mapNV; % Text table of map, rows are labelled with names, columns are sessions

        stacks = mmStack.empty; % array of mmStack, one per numSessions
        
    end
    
    %% Hidden properties
    properties (Hidden=true)
        objectMap % 3D 0 based int, rows are runs, columns are sessions
        objectMapPages % names of the 3rd dimension into objectMap
        
        segmentMap % 3D 0 based int, rows are runs, columns are sessions
        segmentMapPages % names of the 3rd dimension into segmentMap
                
        stackdbTokens %
        intTokens %
        userTokens

        % Each row gives stack db centric indices of connected run of annotations.
        % Columns are sessions.
        % objectRunMap_(i,j) gives stack db centric index of spine in session j.
        % Number of runs (rows) has no intrinsic meaning, it is dependent on
        % how objects are connected (e.g. their dynamics).
        objectRunMap_
        objectRunMap % placeholder so user can use get.objectRunMap but NOT set.objectRunMap
        
        % Same story as objectRunMap_ but gives information for connectivity
        % of segments.
        segmentRunMap_
        segmentRunMap % placeholder for user to use get. set.
end
    
    %% Hidden constant properties
    properties (Hidden=true, Constant)
        % object and segment map are 3d with names pages/slices
        % {'idx'},{'next'},{'nextTP'},{'prev'},{'prevTP'},{'blank'},{'runIdx'},{'dynType'},{'forced'} {'nodeType'},{'segmentID'},{'splitIdx'}
        % todo: finish this and use these constants in code
        kRunIdx = 7; % specifies runIdx slice into objectMap and segmentMap
    end
    
    %% Static methods
    methods (Static=true)
        %% defaultPlotStruct
        function ps = defaultPlotStruct()
            % defaultPlotStruct - Get a default plot struct used in plotting functions
            %    ps = mmMap.defaultPlotStruct()
            % Returns:
            %    ps.roitype (str) : Map Manager ROI type, one of {'spineROI', 'otherROI'}
            %    ps.stat (str) : The name of the stat, check if name is valid with xxx()
            %    ps.stattype (str) : '' to infer type as one of {'stackdb', 'int1', 'int2', 'int3'}
            %    ps.channel = (int) : For int stat type, range is [1:numChannels]
            %    ps.session = (int) : Session index [1..numSessions] for a single session, NaN for all
            %    ps.mapsegment = (int) : Map segment index, NaN for all
            %    ps.plotbad = false;
            %    ps.plotintbad = false;
            %    ps.ploterrorwarning = false;
            % Notes:
            %    Additional fields are filled in and returnd by plot functions.
            %        For example, ps=myMap.GetMapValues(ps).
            
            ps.mapName = ''; % (str) : Filled in by GetMapValues()
            ps.roitype = 'spineROI'; % (str) : Map Manager ROI type, one of {'spineROI', 'otherROI'}
            
            ps.stat = ''; % (str) : The name of the stat, check if name is valid with xxx()
            ps.stattype = ''; % (str) : '' to infer type as one of {'stackdb', 'int1', 'int2', 'int3'}
            ps.channel = 1; % (int) : For int stat type, range is [1:numChannels]
            
            ps.session = NaN; % (int) : Session index [1..numSessions] for a single session, NaN for all
            ps.mapsegment = NaN; % (int) : Map segment index, NaN for all
            
            ps.plotbad = false;
            ps.plotintbad = false;
            ps.ploterrorwarning = false;
        end
    end % methods (static)
    
    %% Public methods
    methods
        
        %todo: make a pretty print
        function disp2(obj)
            strVarName = inputname(1);
            dp = @(p, varargin)(disp_property(strVarName, p, varargin{:}));
            
            disp(sprintf('  <a href="matlab:help mmMap">mmMap</a> object, sessions %d, map segments %d.', obj.numSessions, obj.numMapSegments));

            fprintf('\n');
            disp('  Map properties:');
            
            disp(['    numChannels: ', num2str(obj.numChannels)]);
            disp(['    numSessions: ', num2str(obj.numSessions)]);
            disp(['    numMapSegments: ', num2str(obj.numMapSegments)]);
            
            %dp('numChannels', '%d', obj.numChannels);
            %dp('numSessions', '%d', obj.numSessions);
            %dp('numMapSegments', '%d', obj.numMapSegments);
            dp('mapNV', '[%dx%d table]', size(obj.mapNV,1), size(obj.mapNV,2));
            dp('stacks', '[1x%d <a href="matlab:help mmStack">mmStack</a>]', numel(obj.stacks));
            dp('objectRunMap', '[%dx%d int]', size(obj.objectRunMap_,1), size(obj.objectRunMap_,2));
            dp('segmentRunMap', '[%dx%d int]', size(obj.segmentRunMap_,1), size(obj.segmentRunMap_,2));

            fprintf('\n');
            disp('  <a href="matlab:methods(''mmMap'')">Methods</a>, <a href="matlab:properties(''mmMap'')">Properties</a>');
            fprintf('\n');
            
            %
            function strPropertyLink = property_link(strVarName, strPropertyName, strText)
                if (~exist('strText', 'var') || isempty(strText))
                    strText = strPropertyName;
                end
                strPropertyLink = sprintf('<a href="matlab:%s.%s">%s</a>', strVarName, strPropertyName, strText);
            end
         
            %
            function disp_property(strVarName, strPropertyName, varargin)
                disp(sprintf('    %s: %s', property_link(strVarName, strPropertyName), sprintf(varargin{:})));
            end
        end


        %% mmMap
        function obj = mmMap(mapPath)
        % mmMap Constructor
        %   myMap = mmMap(mapPath)
        % Parameters:
        %   mapPath (str): Full path to Map Manager map folder

            startTime = clock;
            
            % strip off trailing '/'
            if endsWith(mapPath,'/')
                mapPath = mapPath(1,strlength(mapPath)-1);
            end
            
            obj.mapPath = mapPath;
            [parentFolder,obj.mapName] = fileparts(mapPath);
            
            stackdbPath = fullfile(mapPath,'stackdb');
            linePath = fullfile(mapPath,'line');
                        
            mapnvFile = strcat(obj.mapName,'.txt');
            mapnvPath = fullfile(mapPath,mapnvFile);
            if ~(exist(mapnvPath, 'file')==2)
                error(['mmMap did not find main map file:' mapnvPath])
            end
            
            obj.mapNV = readtable(mapnvPath, 'Delimiter', '\t', 'ReadRowNames', true); %, 'TreatAsEmpty', 'N/A');            
            
            n = size(obj.mapNV,2);
            % step through each column and get stack names into /stackdb/ folder
            for j = 1:n
                % can't use GetValue_NV() because it error checks on
                % obj.numSessions and it is not assigned yet
                %stackname = obj.GetValue_NV('hsStack',j);
                stackname = char(obj.mapNV{'hsStack',j});
                if isempty(stackname) || strcmp(stackname,char(NaN))
                    % we are done
                    nTotal = size(obj.mapNV,2);
                    obj.mapNV(:,j:nTotal) = [];
                    break;
                else
                    % load a mmStack
                    obj.stacks(j) = mmStack('', obj, j);
                end % stackname not empty
            end % j sessions
            
            % load object map
            mapfilepath = [obj.mapPath '/' obj.mapName '_objMap.txt'];
            if exist(mapfilepath, 'file') == 2
                [obj.objectMap, obj.objectMapPages] = obj.loadMapFile_(mapfilepath);
                obj.objectRunMap_ = obj.makeRunMap_(obj.objectMap, 'spineROI', 1, 1);
            else
                error(['mmMap did not find object map:' mapfilepath])
            end
            
            % load segment map
            mapfilepath = [obj.mapPath '/' obj.mapName '_segMap.txt'];
            if exist(mapfilepath, 'file') == 2
                [obj.segmentMap, obj.segmentMapPages] = obj.loadMapFile_(mapfilepath);
                obj.segmentRunMap_ = obj.makeRunMap_(obj.segmentMap, '', 0, 0);
                %obj.numSegments = size(obj.segmentRunMap_,1);
            end
            
            loadTime = etime(clock,startTime);
            dispStr = sprintf('   Loaded map %s with %d sessions in %f seconds.', obj.mapName, obj.numSessions, loadTime);
            disp(dispStr);
                        
        end % mmMap() constructor
        
%% getters and setters
        function numSessions = get.numSessions(obj)
            numSessions = size(obj.mapNV,2);
        end
        function set.numSessions(obj, val)
            warning('mmMap.numSessions cannot be set.');
        end
        
        function numMapSegments = get.numMapSegments(obj)
            if ~isempty(obj.segmentRunMap_)
                numMapSegments = size(obj.segmentRunMap_,1);
            else
               numMapSegments = 0;
            end
        end
        function set.numMapSegments(obj, val)
            warning('mmMap.numMapSegments cannot be set.');
        end
        
        function numChannels = get.numChannels(obj)
            numChannels = str2num(obj.GetValue_NV('numChannels',1));
        end
        function set.numChannels(obj, val)
            warning('mmMap.numChannels cannot be set.');
        end
        
        function stackdbTokens = get.stackdbTokens(obj)
            if ~isempty(obj.stacks)
                stackdbTokens = obj.stacks(1).stackdbTokens;
            else
                stackdbTokens = '';
            end
        end
        
        function intTokens = get.intTokens(obj)
            if ~isempty(obj.stacks)
                intTokens = obj.stacks(1).intTokens;
            else
                intTokens = '';
            end
        end
        
        function userTokens = get.userTokens(obj)
            userTokens = '';
            if ~isempty(obj.stacks)
                userTokens = obj.stacks(1).userTokens;
            end
        end
        
        function objectRunMap = get.objectRunMap(obj)
            objectRunMap = obj.objectRunMap_;
        end
        function set.objectRunMap(obj, val)
            warning('mmMap.objectRunMap cannot be set.');
        end
        function segmentRunMap = get.segmentRunMap(obj)
            segmentRunMap = obj.segmentRunMap_;
        end
        function set.segmentRunMap(obj, val)
            warning('mmMap.segmentRunMap cannot be set.');
        end
        
        %% validStats
        % todo: finish this function, return validTypes and add user analysis
        function [validStats, validTypes] = getValidStats(obj)
        % Return a cell array of valid stat names
        
            if ~isempty(obj.stacks)
                [validStats, validTypes] = obj.stacks(1).getValidStats();
            else
                validStats = '';
                validTypes = '';
            end
        end
        
        %% isValidStat
        function [valid, type] = isValidStat(obj, stat, haltOnError)
        % Return true if stat is a valid stat
        %   [valid, type] = myMap.isValidStat(stat)
        % Parameters:
        %   stat (str) :
        % Returns:
        %   valid (boolean) :
        %   type (str) : one of ('stackdb', 'int'), '' if ~valid
 
            if ~exist('haltOnError','var')
                haltOnError = false;
            end
            
            isStackdb = ismember(stat, obj.stackdbTokens);
            isInt = ismember(stat, obj.intTokens);
            isUser = ismember(stat, obj.userTokens);
            if isStackdb || isInt || isUser
                % ok
                valid = true;
                if isStackdb
                    type = 'stackdb';
                elseif isInt
                    type = 'int';
                elseif isUser
                    type = 'user';
                end
            else
                % error
                valid = false;
                type = '';
                if haltOnError
                   dbstack
                   error(['mmError: stat=`' stat '` is not a valid stat for map ' obj.mapName '. ' ...
                       'Use getValidStats() to get a list of valid stats.']);
                end
            end
        end
        
        %% GetValue_NV
        function s = GetValue_NV(obj, name, session)
        % Get value from a session in a map
        %   s = myMap.GetValue_NV(name, session)
        % Parameters:
        %   name (string) : Name of row token into myMap.mapNV
        %   session (int) : 
        % Returns:
        %   s (str) : Use str2num(s) if getting a number
        % Examples:
        %   voxelx = str2num(map.GetValue_NV('dx',2))
        %   voxely = str2num(map.GetValue_NV('dy',2))
        %   voxelz = str2num(map.GetValue_NV('dz',2))
        %   sessionCondition = map.GetValue_NV('condStr',2)
        
            % check that name is a row name
            if ~ismember(obj.mapNV.Properties.RowNames, name)
                error(['error: GetValue_NV() did not find row named ''' name ''' in obj.mapNV'])
            end
            
            % check that session is valid
            if session>obj.numSessions
                error(['error: GetValue_NV() got out of bounds session ''' num2str(session) ''' valid range is [1:' num2str(obj.numSessions) ']'])
            end
            
            s = char(obj.mapNV{name,session});
            
            % don't return ' '
            if s == ' '
                s = ''
            end
        end
        
%         %% GetLine
%         function ps = GetLine(obj, ps)
%         % Get (x,y,z) of a segment tracing
%         %   ps = myMap.GetLine(ps)
%         % Parameters:
%         %   ps.session (int) : session number to get
%         %   ps.mapsegment (int) : map segment to get, NaN for all
%         % Returns:
%         %   ps.line (2D matrix) : Rows are points in tracing
%         %       Columns 1/2/3 are x/y/z respectively
%         %       Units for x/y are um
%         %       Units for z are slices
%         
%             m = size(obj.linedb{ps.session},1);
%             n = 3;
%             ps.line = NaN(m,n);
%             
%             if ps.mapsegment >= 0
%                 theseRows = obj.linedb{ps.session}.ID(:) == ps.mapsegment;
%             else
%                 theseRows = ~isnan(obj.linedb{ps.session}.ID(:));
%             end
%             
%             ps.line(theseRows,1) = obj.linedb{ps.session}.x(theseRows);
%             ps.line(theseRows,2) = obj.linedb{ps.session}.y(theseRows);
%             ps.line(theseRows,3) = obj.linedb{ps.session}.z(theseRows);
%             
%         end
        
%         %% LoadStacks
%         function ps = LoadStacks(obj,ps)
%         % Load images for a stack for a session
%         %   ps = myMap.LoadStacks(ps)
%         % Parameters:
%         %   ps.sessions (int) : Session to load
%         %   ps.channel (int) : Image channel to load
%         % Returns:
%         %   ps.images{ps.session}
%             
%             % numSlices = str2num(obj.GetValue_NV('pz',ps.session));
%             stackname = obj.GetValue_NV('hsStackNV',ps.session);
%             chStr = ['_ch' string(ps.channel)];
%             stackFile = [stackname chStr '.tif'];
%             stackPath = strjoin([obj.mapPath '/' 'raw' '/' stackFile], '');
%             stackPath = char(stackPath);
%             % question: I want images to be part of mmMap object
%             % This seems to require obj = obj.LoadStacks(ps)
%             % not sure if this is a good idea as we are making extra copies ? slow?
%             %obj.images{ps.session} = imread(stackPath);
%             
% %bug: this will only hold the last channel load, fix this
%             % question: can I read a multi-page tiff with one command?
%             w = warning ('off','all'); % suppress warnings
%             tiffInfo = imfinfo(stackPath);
%             warning(w) % restore
%             numSlices = size(tiffInfo,1);
%             for slice = 1:numSlices
%                 ps.images{ps.session}(:,:,slice) = imread(stackPath, slice);
%             end
%         end
        
        %% GetMapDynamics
        function ps = GetMapDynamics(obj, ps)
        % Get map dynamics
        %   ps = myMap.GetMapDynamics(ps)
        % Parameters:
        %   
        % Returns:
        %   ps.added (2D matrix of boolean) : 
        %   ps.addedRuns (2D matrix of boolean) : 
        %   ps.subtracted (2D matrix of boolean) : 
        %   ps.subtractedRuns (2D matrix of boolean) : 
        %   ps.transient (2D matrix of boolean) : 
        %   ps.alwaysPresent (2D matrix of boolean) : 
         
            %
            % todo: use main getmapvalues to get valid candidates based on
            % (roiType, bad, etc)
            % todo: [done] expand this to take ps and return
            %   all dynamics (add, sub, tran, addrun, subrun)
            
            % cludge to get something from GetMapValues
            if isempty(ps.stat)
                ps.stat = 'pDist';
            end
            
            ps = obj.GetMapValues(ps);
            [m,n] = size(ps.stackdbidx);
            %[m,n] = size(obj.objectRunMap);
            
            %what we will fill in
            ps.added = nan(m,n);
            ps.addedRuns = nan(m,n);
            ps.subtracted = nan(m,n);
            ps.subtractedRuns = nan(m,n);
            ps.transient = nan(m,n);
            ps.alwaysPresent = nan(m,n);
            ps.x = nan(m,n);
            
            for i = 1:m % runs
                setAlwaysPresent = false; %
                isAdded = 0;
                jSubtracted = nan;
                for j = 1:n % sessions
                    %if isnan(obj.objectRunMap(i,j))
                    %    continue
                    %end
                    if isnan(ps.stackdbidx(i,j))
                        continue
                    end
                    
                    %case 'added'
                    if j>1 && isnan(ps.stackdbidx(i,j-1))
                        ps.added(i,j) = 1;
                    end
                    %case 'added run'
                    if j>1 && isnan(ps.stackdbidx(i,j-1))
                        ps.addedRuns(i,j) = 1;
                        isAdded = 1;
                    end
                    if isAdded
                        ps.addedRuns(i,j) = 1;
                    end
                    %case 'subtracted'
                    if j<n && isnan(ps.stackdbidx(i,j+1))
                        ps.subtracted(i,j) = 1;
                    end
                    %case 'subtracted run'
                    if j<n && isnan(ps.stackdbidx(i,j+1))
                        ps.subtractedRuns(i,j) = 1;
                        jSubtracted = j;
                    end
                    %case 'transient'
                    if j>1 && j<n && isnan(ps.stackdbidx(i,j-1)) && isnan(ps.stackdbidx(i,j+1))
                        ps.transient(i,j) = 1;
                        % break
                    end
                    %case 'always present'
                    if isnan(ps.stackdbidx(i,j))
                        % not 'always present'
                        ps.alwaysPresent(i,:) = NaN;
                        setAlwaysPresent = true;
                        %break
                    elseif ~setAlwaysPresent
                        ps.alwaysPresent(i,j) = 1;
                    end
                    if ~isnan(jSubtracted) %&& cmpstr(thisType,'subtracted run')
                        ps.subtractedRun(i,1:jSubtracted) = 1;
                    end
                    ps.x(i,j) = j;
                end % j = 1:n sessions
            end % i = 1:m runs
        end
        
        %% GetMapValuesCond
        function condMean = GetMapValuesCond(obj, ps, theCond)
        %
        % Parameters:
        %   theCond (str) : Condition to search for, can use wildcard '*'.
        % Returns:
        %   Vector of mean from rows of ps.val where each element (in the returned vector)
        %       is mean across rows of ps.val only for sessions (columns) that
        %       matched wildcard condition theCond. 
        
            ps = obj.GetMapValues(ps);
            mVal = size(ps.val,1);
            
            % always return 1 column, the average across rows of columns
            % matching theCond
            condMean = NaN(mVal,1);
            
            % strip down ps.val to only contain colums matching theCond
            outCol = 0;
            tmpOut = NaN(mVal,1); % accumulate match in here
            matchList = [];
            for j = 1:obj.numSessions
                mapCond = obj.GetValue_NV('condStr',j);
                match = regexp(mapCond, regexptranslate('wildcard',theCond));
                if match == 1 % match can be >1
                    outCol = outCol + 1;
                    tmpOut(:,outCol) = ps.val(:,j);
                    matchList = [matchList ' ' num2str(j)];
                end
            end
            if outCol
                disp(['GetMapValuesCond() map:' obj.mapName ' cond:' theCond ...
                    ' taking mean of sessions ' matchList]);
                condMean = mean(tmpOut,2);
            end
        end
    
        %% GetMapValues
        function ps = GetMapValues(obj, ps)
        %GetMapValues - Get values of annotations from a map.
        %   Syntax:
        %       ps = myMap.GetMapValues(ps)
        %   Parameters:
        %       ps (Struct) : Use mmMap.defaultPlotStruct() to get template
        %       ps.roitype (str) : 'spineROI' | 'otherROI'
        %       ps.stat (str) : A stat name. Get valid stats with myMap.getValidStats()
        %       ps.channel (int) : Use this for stat type 'int'
        %       ps.mapSegment (int) : 1..myMap.numMapSegment
        %       ps.plotBad (boolean) :
        %       ps.plotintbad (boolean) :
        %       ps.ploterrorwarning (boolean) :
        %   Returns:
        %       ps.val (2D matrix of float) :
        %       ps.sessions (2D matrix of float) :
        %       ps.days (2D matrix of float) :
        %       ps.stackdbidx (2D matrix of int) :
        %   Examples:
        %       ps = mmMap.defaultPlotStruct();
        %       ps.stat = 'ubssSum';
        %       ps.channel = 2;
        %       ps = myMap.GetMapValues(ps);
        %       plot(ps.sessions, ps.val, 'ok'); % plot ubssSum versus session
        %       plot(ps.days, ps.val, 'ok'); % plot ubssSum versus days
            
            % display error if ps.channel or ps.session are invalid for *this map
            obj.validChannel_(ps.channel,1);
            obj.validSession_(ps.session,1);
            obj.isValidStat(ps.stat,1);
            
            ps.mapName = obj.mapName;
            
            [m,n] = size(obj.objectRunMap_);
            
            % if ps.session then limit to one column
            startSession = 1;
            stopSession = n;
            if ~isnan(ps.session)
                n = 1;
                startSession = ps.session;
                stopSession = ps.session;
            end
            
            % make return matrices
            ps.val = NaN(m,n);
            ps.sessions = NaN(m,n); % just session for now
            ps.days = NaN(m,n);
            ps.stackdbidx = NaN(m,n);
            
            % todo: switch this to a constant
            runIdx = 7;
            
            % todo: put this into function_
            %if ps.stattype
            %    stattype = ps.stattype;
            %else
            %    stattype = obj.getStatType_(ps.stat, 1);
            %end
            
            % reverse lookup stack index -> run index
            reverseLookup = nan(size(obj.objectMap,1),size(obj.objectMap,2));
            
            stack_ps = ps;
            colIdx_lhs = 1;
            for j = startSession:stopSession % sessions
                % convert map centric ps.mapsegment into stack centic stackSegment
                stackSegment = NaN;
                if ~isnan(ps.mapsegment)
                    stackSegment = obj.segmentRunMap_(ps.mapsegment,j);
                    if isnan(stackSegment)
                        % No corresponding segment in j'th stack
                        continue;
                    end
                end
                stack_ps.stacksegment = stackSegment;
                
                % main engine to get annotations from stack
                stack_ps = getStackValues(obj.stacks(j), stack_ps);
                
                % make a reverse lookup same size as objectMap
                % use  in plot callbacks, given a stack index -> run index
                reverseLookup(stack_ps.stackdbidx,j) = obj.objectMap(stack_ps.stackdbidx,j,obj.kRunIdx);
                
                final_lhs = obj.objectMap(stack_ps.stackdbidx,j,runIdx);
                                                
                % assign return values
                ps.val(final_lhs,colIdx_lhs) = stack_ps.val;
                ps.sessions(final_lhs,colIdx_lhs) = j;
                ps.days(final_lhs,colIdx_lhs) = str2num(obj.GetValue_NV('days',j));
                ps.stackdbidx(final_lhs,colIdx_lhs) = stack_ps.stackdbidx;
                ps.reverseLookup = reverseLookup;
                
                colIdx_lhs = colIdx_lhs + 1;
            end % j sessions
            
            % strip out nan rows
            % causes problems if we are reducing to one session
            % see: https://www.mathworks.com/matlabcentral/answers/68510-remove-rows-or-cols-whose-elements-are-all-nan
            %out = A(all(~isnan(A),2),:); % for nan - rows
            %out = A(:,all(~isnan(A)));   % for nan - columns
            if isnan(ps.session)
                % this form seems to remove rows that are all nan
                %ps.stackdbidx(any(~isnan(ps.stackdbidx),2),:)
                ps.val = ps.val(any(~isnan(ps.stackdbidx),2),:);
                ps.sessions = ps.sessions(any(~isnan(ps.stackdbidx),2),:);
                ps.days = ps.days(any(~isnan(ps.stackdbidx),2),:);
                ps.stackdbidx = ps.stackdbidx(any(~isnan(ps.stackdbidx),2),:);
            end
            
        end % GetMapValues
        
        function [retVal,retVec] = segmentAnalysis(obj, ps, f)
        %segmentAnalysis - Call a function for each map segment
        %    [retVal, retVec] = myMap.segmentAnalysis(ps, 'myFunction');
        %See segmentStats.m and mysegfun.m for examples of 'myFunction'.
            if ~exist(f, 'file')
                error(['mmMap.segmentAnalysis() did not find .m file for function `' f '`'])
            end
            
            fnReference = str2func(f);
                        
            %retVal = nan(obj.numMapSegments, obj.numSessions);
            %retVec = nan(obj.numMapSegments, obj.numSessions);

            for i = 1:obj.numMapSegments
                
                % get map stats for theStat
                ps.mapsegment = i;
                ps = obj.GetMapValues(ps); % user specified stat (theStat)
                
                % get map stats for pDist
                pDist_ps = ps;
                pDist_ps.stat = 'pDist';
                pDist_ps = obj.GetMapValues(pDist_ps); % pDist
                
                for j = 1:obj.numSessions
                    stackdbSegment = obj.segmentRunMap_(i,j);
                    if isnan(stackdbSegment)
                        % no stack centric segment at session j
                        continue
                    end
                    %
                    % call analysis function f for each segment in map
                    [retVal(i,j), retVec(i,j)] = fnReference(obj, j, i, ps.val(:,j), pDist_ps.val(:,j));
                    
                end % j numSessions
            end % i numMapSegments
        end

        %% addUserStat
        function addUserStat(obj, ps, newStatName, newStatValues)
        % addUserStat - Add a user stat to map
        %   myMap.addUserStat(ps, newStatName, newStatValues)
        % Arguments:
        %   ps (plot struct) : 
        %   newStatName (str) : Name of stat to add
        %   newStatValues (2D matrix of float) : Same shape as ps.val
        % Returns:
        %   Assigns obj.stacks(:).userstat(:,{stat})
        % Example:
        %   ps = mmMap.defaultPlotStruct();
        %   ps.stat = 'pDist';
        %   ps = obj.GetMapValues(ps);
        %   newStatName = 'myNewStat';
        %   newStatValues = ps.val + 100;
        %   myMap.addUserStat(ps, newStatName, newStatValues)        
        
            % todo: error check newStatValues for correct shape
            
            for j = 1:obj.numSessions
                goodCol_map = ~isnan(ps.stackdbidx(:,j));
                theseIndices_stack = ps.stackdbidx(goodCol_map,j);
                % make values for stack
                mStack = obj.stacks(j).numAnnotations;
                theseValues = nan(mStack,1);
                theseValues(theseIndices_stack) = newStatValues(goodCol_map,j);
                %
                obj.stacks(j).addUserStat(newStatName, theseValues);
            end % j
        end % addUserStat
        
%todo: also save mapNV so user can update condition
        %% save
        function save(obj)
        % save - Save user annotations
        %   This saves a /stackdb/userstat.txt file for each session in map
        %   User stats will be loaded the next time the map is loaded
        %
        %   IMPORTANT: If you save user stats and then add/delete annotations
        %       in Igor Pro - Map Manager, your Matlab saved user stats will no longer
        %       be valid and need to be regerated again with addUserStat().
            for j = 1:obj.numSessions
                obj.stacks(j).save();
            end
        end
        
        %% find
        function t = find(obj, stat, findStr)
        %find - Find a string in mmStack 'notes', 'error', 'warning'
        %    t = myMap.find('note', '*');
        %Returns:
        %    t (table) : A table of matching annotations
        
            % todo: this should take ps, build a 2d object map hit matrix and then pass back ps.hits(m,n) of hits
            t = table();
            %t.Properties.VariableNames = {'session'};
            for j = 1:obj.numSessions
                stackTable = obj.stacks(j).find(stat, findStr);
                mStackTable = size(stackTable,1);
                if mStackTable>0
                    stackTable.session = (zeros(mStackTable,1) + j);
                    newNumCols = size(stackTable,2);
                    stackTable = [stackTable(:,newNumCols) stackTable(:,1:newNumCols-1)];
                    
                    t = [t; stackTable];
                end
            end % j sessions
        end
        
%% Plot functions using mmPlot class
        function ps = plot0(obj,ps)
        % plot0 - Plot a canonical map manager map of spine position versus session
        %   ps = myMap.plot0(ps);
        % Note:
        %   This plot is interactive, user clicks will display annotation
        %   information and select a run
            ps = mmPlot.plot0(obj, ps);
        end
        
        function ps = plotStat(obj, ps, vargin)
        % plotStat - Plot a stat versus sessions
        %   ps = myMap.plotStat(ps);
            if exist('vargin','var')
                ps = mmPlot.plotStat(obj, ps, vargin);
            else
                ps = mmPlot.plotStat(obj, ps);
            end
        end

        function ps = plotStat2(obj, xps, yps)
        % plotStat2 - Plot two stats x and y
        %   ps = myMap.plotStat2(xps, yps);
            ps = mmPlot.plotStat2(obj, xps, yps);
        end

        function plotMaxProject(obj, session, channel)
        % plotMaxProject - Plot maximum projection and overlay tracing and annotations
        %   myMap.plotMaxProject(Session, channel);
            stacksegment = NaN;
            showAnnotations = true;
            showLines = true;
            obj.stacks(session).plotMaxProject(channel, stacksegment, showAnnotations, showLines);  
        end
        
    end % methods
    
    %% Hidden methods
    methods (Hidden=true)
        
        function [y,layerNames] = loadMapFile_(~, mapfilepath)
        % load 3d matrix of either (objectMap, segmentMap)
        % File is text and has 3rd dimension arranged as 'blocks'
            if exist(mapfilepath, 'file') == 2
                fid = fopen(mapfilepath);
                lineHeader = fgetl(fid);
                fclose(fid);
                lineHeader = strsplit(lineHeader, ';');
                numberOfHeaderRows = 0;
                % initialize variables for header (name=value) we are expecting
                rows = NaN;
                cols = NaN;
                blocks = NaN;
                pages = '';
                % read header line
                for i = 1:length(lineHeader)
                    nameValue = strsplit(lineHeader{i},'=');
                    switch (nameValue{1})
                        case 'rows'
                            rows = str2num(nameValue{2});
                        case 'cols'
                            cols = str2num(nameValue{2});
                        case 'blocks'
                            blocks = str2num(nameValue{2});
                        case 'blockNames'
                            blockNames = nameValue{2}; % comma seperated list
                            layerNames = strsplit(blockNames,',');
                           
                    end
                end % for i in lineHeader
                % sprintf('rows=%d cols=%d blocks=%d, blockNames=%s', rows, cols, blocks, blockNames)
                
                mapMatrix = dlmread(mapfilepath, '\t', 1, 0); % start at second line, first column (NOT 1 based)
                
                % reshape into a 3D matrix of size [rows,cols,blocks]
                % reshape is column wise (we want row wise)
                % thus, this does not work, y = reshape(mapMatrix, [rows,cols,blocks]);
                % answer was here: https://www.mathworks.com/matlabcentral/answers/36563-reshaping-2d-matrix-into-3d-specific-ordering
                % out = permute(reshape(a',[c,r/nlay,nlay]),[2,1,3])
                origRows = size(mapMatrix,1);
                y = permute(reshape(mapMatrix',[cols,origRows/blocks,blocks]),[2,1,3]);
                
                % transform stack db indices to 1 based (from 0 based)
                y(:,:,2) = y(:,:,2) + 1;
                y(:,:,4) = y(:,:,4) + 1;
                y(:,:,7) = y(:,:,7) + 1;
                
            end % mapfilepath exists
        end
        
        function runMap = makeRunMap_(obj, theMap, theROI, assignRunIdx, checkSanity)
        % theMap is (obj.objectMap, obj.segmentMap)

            % todo: switch these to hidden property constants defined above in class
            index = 1; % should get index of {'index'} from obj.objectMapPages
            next = 2; % should get index of {'next'} from obj.objectMapPages
            prev = 4; % should get index of {'prev'} from obj.objectMapPages
            runIdx = 7; % use as sanity check for code below
                        
            m = size(theMap,1);
            n = size(theMap,2);
            runMap = nan(m*n,n); % will resize by trimming empty rows beyond outRow
            outRow = 1;
            for j = 1:n % sessions
                for i = 1:m
                    if ~isnan(theMap(i,j,index)) && (j==1 || isnan(theMap(i,j,prev)))
                        currNode = i;
                        
                        % only consider spineROI
                        if theROI
                            thisROI = obj.stacks(j).stackdb.roiType(currNode);
                            if ~strcmp(thisROI,theROI)
                                outRow = outRow + 1;
                                continue
                            end
                        end
                        
                        for k = j:n
                            runMap(outRow,k) = currNode; %could be theMap[i][j][index]
                            
                            if assignRunIdx
                                obj.objectMap(currNode,k,runIdx) = outRow;
                            end
                            
                            % yyy is copied pasted from igor
                            %if checkSanity
                            %    if currNode ~= yyy(outRow,k)
                            %        sprintf('error')
                            %        obj.stackdb{k}.roiType(currNode)
                            %    end
                            %end
                            
                            if isnan(theMap(currNode,k,next))
                                outRow = outRow + 1;
                                break
                            end
                            currNode = theMap(currNode,k,next);
                        end % k in column/session loop
                    end % j columns/sessions
                end % i rows
            end % j columns
            runMap(outRow:m*n,:) = [];
        end
        
        function stattype = getStatType_(obj, stat, failonerror)
        % infer which object ps.stat is in using column tokens
        % if in both, stackdb trumps int
            stattype = '';
            isStackdb = ismember(stat, obj.stackdbTokens);
            isInt = ismember(stat, obj.intTokens);
            isUser = ismember(stat, obj.userTokens);

            if isStackdb
                stattype = 'stackdb';
            elseif isInt
                stattype = 'int';
            elseif isUser
                stattype = 'userstat';
            else
                errorStr = ['mmMap.getStatType_() did not find ps.stat: `' stat '` in map ' obj.mapName];
                if failonerror
                    error(errorStr)
                else
                    errorStr
                end
            end
        end
        
        function ok = validSession_(obj, session, haltOnError)
            ok = isnan(session) || (session>=1 && session<=obj.numSessions);
            if isempty(haltOnError)
                haltOnError = 0;
            end
            if ~ok && haltOnError
                error(['mmError: Got bad ps.session=' num2str(session) ' for map ' obj.mapName ' ' ...
                    'Valid values are NaN or scaler in [1:' num2str(obj.numSessions) ']']);
            end
        end
        
        function ok = validChannel_(obj, channel, haltOnError)
            ok = isnan(channel) || (channel>=1 && channel<=obj.numChannels);
            if isempty(haltOnError)
                haltOnError = 0;
            end
            if ~ok && haltOnError
                error(['mmError: Got bad ps.channel=' num2str(channel) ' for map ' obj.mapName ' ' ...
                    'Valid values are NaN or scaler in [1:' num2str(obj.numChannels) ']']);
            end
        end
        
    end % methods (hidden)
end % classdef mmMap
