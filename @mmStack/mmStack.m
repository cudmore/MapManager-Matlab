%mmStack - A class to load, extract, and analyze annotations in a Map Manager stack.
%
%To construct a mmStack:
%   myStack = mmStack(tiffPath)
%
%mmStack Properties:
%   stackName (str) :
%   tiffPath (str) :
%   inMap (boolean) : True if stack is inserted into a mmMap, false otherwise.
%   stackdb (table of str) : table of annotations, one row per annotation
%   int1 (table of float) : table of intensity values for each annotations
%   int2 (table of float) :
%   int3 (table of float) :
%   userstat (table of float) : table of user created annotation values
%   linedb (table of float) : table of all segment tracings in the stack
%
%Annotations:
%   getStackValues - Get annotation from stack
%   addUserStat - 
%
%Tracing:
%   getTracing - Get one or all segment tracings
%
%Images:
%   loadStack - Load the image stack
%   unloadStack - Unload the image stack
%
%Utility
%   find - find annotations by their note stat
%   save - save user annotations added with addUserStat
%
% <a href="matlab:methods('mmmStack')">List methods</a>, <a href="matlab:properties('mmmStack')">properties</a>

% Author: Robert Cudmore
% Date: 20171014
% Email: robert.cudmore@gmail.com
% Website: http://www.cudmore.io/mapmanager

classdef mmStack < handle

    properties
        stackName = ''

        % single time-point
        tiffPath = '';
        enclosingFolder = ''
        
        
        % created from mmMap
        inMap = false;
        myMap = ''
        mySession = NaN;
        
        stackdb = [];
        int1 = [];
        int2 = [];
        int3 = [];
        userstat = [];
        
        linedb = [];
        
        vx = 1; % voxel scale (um)
        vy = 1;
        vz = 1;
        
        stackdbTokens = ''; % get.stackdbTokens 
        intTokens = ''; % get.intTokens
        userTokens = ''
        
        numChannels = NaN; % get.numChannels
        numAnnotations = NaN;
        numSegments = NaN;
        
        images = {}; % (channel, rows, cols, slices)
        
    end % properties
    
    methods

        % constructor
        function obj = mmStack(tiffPath, theMap, theSession)
            obj.tiffPath = tiffPath;

            % - Assign 'writable' flag
            if (exist('theMap', 'var') && exist('theSession', 'var')) % || isempty(theMap))
                obj.inMap = true;
                obj.myMap = theMap;
                obj.mySession = theSession;
                stackName = obj.myMap.GetValue_NV('hsStack',theSession);
                obj.stackName = obj.stripchannel_(stackName);
            else
                % single timepoint stack
                
            end
            
            obj.loadAnnotations();
            
            for i = 1:obj.numChannels
                obj.images{i} = [];
            end
            
        end % mmStack constructor
        
        %% getter and setter
        function stackdbTokens = get.stackdbTokens(obj)
            if ~isempty(obj.stackdb)
                stackdbTokens = obj.stackdb.Properties.VariableNames;
            else
                stackdbTokens = '';
            end
        end
        
        function intTokens = get.intTokens(obj)
            if ~isempty(obj.int1)
                intTokens = obj.int1.Properties.VariableNames;
            else
                intTokens = '';
            end
        end
        
        function userTokens = get.userTokens(obj)
            if ~isempty(obj.userstat)
                userTokens = obj.userstat.Properties.VariableNames;
            else
                userTokens = '';
            end
        end
        
        function channels = get.numChannels(obj)
            channels = 1;
            if ~isempty(obj.int2)
                channels = 2;
            elseif ~isempty(obj.int3)
                channels = 3;
            end
        end
        
        function numAnnotations = get.numAnnotations(obj)
            numAnnotations = size(obj.stackdb,1);
        end
        
        function [validStats, validTypes] = getValidStats(obj)
        % Get a list of valid stat names.
            validStats = [obj.stackdbTokens, obj.intTokens, obj.userTokens];
            validTypes = ''
        end
        
        %% loadAnnotations
        function loadAnnotations(obj)
        % Load annotations for a stack.
            if obj.inMap
                stackdbPath = fullfile(obj.myMap.mapPath,'stackdb');
                linePath = fullfile(obj.myMap.mapPath,'line');
                obj.vx = str2num(obj.myMap.GetValue_NV('dx',obj.mySession));
                obj.vy = str2num(obj.myMap.GetValue_NV('dy',obj.mySession));
                obj.vz = str2num(obj.myMap.GetValue_NV('dz',obj.mySession));
            else
                stackdbPath = '';
                linePath = '';
            end
            
            stackname = obj.stripchannel_(obj.stackName);
            stackdbFile = strcat(stackname, '_db2.txt');
            stackdbFilePath = fullfile(stackdbPath, stackdbFile);

            lineFile = strcat(stackname, '_l.txt');
            lineFilePath = fullfile(linePath, lineFile);
            
            int1File = strcat(stackname, '_int1.txt');
            int1FilePath = fullfile(stackdbPath, int1File);
            
            int2File = strcat(stackname, '_int2.txt');
            int2FilePath = fullfile(stackdbPath, int2File);
            
            int3File = strcat(stackname, '_int3.txt');
            int3FilePath = fullfile(stackdbPath, int3File);
            
            userFile = strcat(stackname, '_user.txt');
            userFilePath = fullfile(stackdbPath, userFile);

            if exist(stackdbFilePath, 'file') == 2
                obj.stackdb = readtable(stackdbFilePath, 'Delimiter', ',', 'TreatAsEmpty', 'NA');
                
                %bug: need to convert all stackdb{:} (note, error, warning) to text
                % when one of these is empty it is coming in as NaN
                if iscellstr(obj.stackdb.note)
                    % OK
                else
                    %{j 'note was NaN and is now cell array'}
                    obj.stackdb.note = num2cell(obj.stackdb.note);
                end
                if iscellstr(obj.stackdb.error)
                    % OK
                else
                    %{j 'error was NaN and is now cell array'}
                    obj.stackdb.error = num2cell(obj.stackdb.error);
                end
                if iscellstr(obj.stackdb.warning)
                    % OK
                else
                    %{j 'warning was NaN and is now cell array'}
                    obj.stackdb.warning = num2cell(obj.stackdb.warning);
                end
                
                % make parentID 1 based
                obj.stackdb.parentID(:) = obj.stackdb.parentID(:) + 1;
                
                % fix Idx, it is out of order in map manager file
                % (not used in map manager)
                mStack = size(obj.stackdb,1);
                obj.stackdb.Idx = (1:mStack)';
                
            else
                error(['myerror:' 'mmStack did not find stack db file:' stackdbFilePath])
            end
            
            if exist(lineFilePath, 'file') == 2
                fid = fopen(lineFilePath);
                lineHeader = fgetl(fid);
                fclose(fid);
                lineHeader = strsplit(lineHeader, ';');
                numberOfHeaderRows = 0;
                for i = 1:length(lineHeader)
                    nameValue = strsplit(lineHeader{i},'=');
                    if strcmp(nameValue{1},'numHeaderRow')
                        numberOfHeaderRows = str2num(nameValue{2});
                    end
                end % for
                linesToSkip = numberOfHeaderRows + 2;
                obj.linedb = readtable(lineFilePath, 'Delimiter', ',', 'HeaderLines', linesToSkip);
  
                obj.linedb.ID(:) = obj.linedb.ID(:) + 1;
            else
                % OK, sometimes we don't have a line
            end
            
            if exist(int1FilePath, 'file') == 2
                obj.int1 = readtable(int1FilePath, 'Delimiter', ',');
            else
                error(['myerror:' 'mmStack did not find int1 file' int1FilePath])
            end
            
            if exist(int2FilePath, 'file') == 2
                obj.int2 = readtable(int2FilePath, 'Delimiter', ',');
            else
                % OK
            end
            
            if exist(int3FilePath, 'file') == 2
                obj.int3 = readtable(int3FilePath, 'Delimiter', ',');
            else
                % OK
            end
            
            if exist(userFilePath, 'file') == 2
                obj.userstat = readtable(userFilePath, 'Delimiter', ',');
            else
                % make a userstat table
                % append to this table with adduserstat()
                mStack = size(obj.stackdb,1);
                unity = 1:mStack;
                unity = unity';
                obj.userstat = table(unity);
                obj.userstat.Properties.VariableNames = {'Idx'};
            end
        end % loadAnnotations
                
        %% getStackValues - 
        function ps = getStackValues(obj, ps)
        % Get values for a stat
        %   ps = myStack.getStackValues(ps);
        % Parameters
        %   ps.stat (str) : 
        %   ps.stacksegment (int) :
        %   ps.plotbad (boolean) :
        %   ps.plotintbad (boolean) : 
        %   ps.ploterrorwarning (boolean) : 
        %   ps.channel (int) :
        % Returns:
        %   ps.val (float vector) : values of ps.stat
        %   ps.stackdbidx (int vector) : indices into stack db
        
            if ps.stattype
                stattype = ps.stattype;
            else
                stattype = obj.getStatType_(ps.stat, 1);
            end

            mStack = obj.numAnnotations;
            allOnes = ones(mStack,1);

            % spineROI
            if ps.roitype
                spineROI_rhs = ismember(obj.stackdb.roiType, {ps.roitype});
            else
                spineROI_rhs = allOnes;
            end
            % parent segment
            if ps.stacksegment >= 0
                stacksegment_rhs = obj.stackdb.parentID(:) == ps.stacksegment;
            else
                stacksegment_rhs = allOnes;
            end
            % not isBad
            if ps.plotbad
                isGood_rhs = allOnes;
            else
                isGood_rhs = ~(obj.stackdb.isBad(:) == 1);
            end
            % not intBad
            if ps.plotintbad
                isIntGood_rhs = allOnes;
            else
                isIntGood_rhs = ~(obj.stackdb.intBad(:) == 1);
            end
            
            % errors and warnings (from intensity analysis)
            if ps.ploterrorwarning
                errorWarning_rhs = allOnes;
            else
                % todo: FIX
                if iscellstr(obj.stackdb{:,'error'})
                    errorWarning_rhs = ismember(obj.stackdb.error, {''});
                else
                    %was not cellstr, probably no errors and it defaulted to nan
                    errorWarning_rhs = allOnes;
                end
            end
            
            goodIdx = spineROI_rhs & stacksegment_rhs & isGood_rhs & isIntGood_rhs & errorWarning_rhs;

            % pull the stat
            switch (stattype)
                case 'stackdb'
                    ps.val = table2array(obj.stackdb(goodIdx,{ps.stat}));
                case 'int'
                    switch ps.channel
                        case 1
                            ps.val = table2array(obj.int1(goodIdx,{ps.stat}));
                        case 2
                            ps.val = table2array(obj.int2(goodIdx,{ps.stat}));
                        case 3
                            ps.val = table2array(obj.int3(goodIdx,{ps.stat}));
                        otherwise
                            error(['mmStack.getStackValues() did not get ps.channel for stat `' ps.stat '` of type int']);
                    end
                case 'userstat'
                    ps.val = table2array(obj.userstat(goodIdx,{ps.stat}));
            end
            
            tmpIdx = 1:mStack;
            tmpIdx = tmpIdx';
            ps.stackdbidx = tmpIdx(goodIdx==1);
            
        end % function getStackValues
        
        %% getTracing()
        function tracing = getTracing(obj, stacksegment)
        % Get the x/y/z coordinates of a segment tracing.
        %   tracing_xyz = myStack.getTracing(stacksegment)
        % Parameters:
        %   ps.stacksegment (int) : nan for all
        % Returns:
        %   tracing (mx3 matrix of float) : m is number of points in all
        %   tracings in stack
        
            m = size(obj.linedb,1);
            n = 3;
            tracing = NaN(m,n);
            
            if ~isnan(stacksegment)
                theseRows = obj.linedb.ID(:) == stacksegment;
            else
                theseRows = ~isnan(obj.linedb.ID(:));
            end
            
            tracing(theseRows,1) = obj.linedb.x(theseRows);
            tracing(theseRows,2) = obj.linedb.y(theseRows);
            tracing(theseRows,3) = obj.linedb.z(theseRows);
        end
        
        %% loadStack
        function ok = loadStack(obj,channel)
        % Load images for a stack for a session
        %   ok = myStack.loadStack(channel)
        % Parameters:
        %   channel (int) : Image channel to load
        % Modifies:
        %   obj.images(channel)
        % Returns:
        %   ok (boolean) : Images for stack were successfully loaded
            
            % numSlices = str2num(obj.GetValue_NV('pz',ps.session));
            %stackname = obj.GetValue_NV('hsStackNV',ps.session);
            chStr = ['_ch' string(channel)];
            stackFile = [obj.stackName chStr '.tif'];
            if obj.inMap
                stackPath = strjoin([obj.myMap.mapPath '/' 'raw' '/' stackFile], '');
            else
                
            end
            stackPath = char(stackPath);
            
            % check that stackPath exists
            if exist(stackPath) ~= 2
                error(['mmStack.loadStack() file not found:' stackPath])
            end
            
            % check if already loaded
            if ~isempty(obj.images{channel})
                disp([obj.stackName ' channel ' num2str(channel) ' is already loaded']);
                ok = 1;
                return;
            end
                
            % question: can I read a multi-page tiff with one command?
            w = warning ('off','all'); % suppress warnings
            tiffInfo = imfinfo(stackPath);
            warning(w) % restore
            numSlices = size(tiffInfo,1);
            disp(['   mmStack.loadStack() ' obj.stackName ' loading ' num2str(numSlices) ' slices...']);
            for slice = 1:numSlices
                obj.images{channel}(:,:,slice) = imread(stackPath, slice);
            end
            ok = true;
        end % loadStack
        
        function unloadStack(obj, channel)
        % Unload stack images for a channel
            
            % todo: check valid channel

            obj.images{channel} = [];
        end
        
        function addUserStat(obj, newStatName, newStatValues)
        % Add a user stat to stack annotations
        
            % check that stat is not already a column
            failOnError = 0;
            newStatType = obj.getStatType_(newStatName, failOnError);

            if ~strcmp(newStatType,'')
               %disp([newStatName ' is already a column in userstat']); 
            else
                % expand obj.userstat to include new column named
                % 'stat' and with values of NaN
                
                mStack = size(obj.stackdb,1);
                % make a new table and concatenate to existing
                newTable = table(NaN(mStack,1));
                newTable.Properties.VariableNames = {newStatName};
                obj.userstat = [obj.userstat newTable];
            end
        
            % fill in table with new stat values
            obj.userstat(:,newStatName) = array2table(newStatValues);
        end % addUserStat
        
        function save(obj)
        % Save stack userstat
            if obj.inMap
                stackdbPath = fullfile(obj.myMap.mapPath,'stackdb');
                userStatFile = strcat(obj.stackName, '_user.txt');
                userStatFilePath = fullfile(stackdbPath, userStatFile);
                disp(['   mmStack.save() is saving userstat for stack ' obj.stackName ' file:' userStatFile]);
                writetable(obj.userstat, userStatFilePath);
            else
                % todo: save into /stackdb/ of obj.enclosingFolder
            end
        end % save
        
        function t = find(obj, stat, findStr)        
        % Find a string in stackdb
        %   t = myStack.find(stat, findStr)
        % Arguments
        %   stat (str) : COlumn to search, one of {'note', 'error', 'warning'}
        %   findStr (str) : String to search for, can be '*' to find all.
        % Returns:
        %   t (table) : One row per annotaiton found in stackdb
            t = table();
            % if no strings then it is col num with NaN
            if iscellstr(obj.stackdb{:,stat})
                if strcmp(findStr,'*')
                    match = ~ismember(obj.stackdb{:,stat},{''});
                else
                    match = ismember(obj.stackdb{:,stat},{findStr});
                end
                if sum(match)
                    t = obj.stackdb(match,:);
                end % sum(match)
            end
        end % find
        
    end % methods

    methods (Hidden=true)
        function ret = stripchannel_(~, name)
            % Strip _ch1, _ch2, _ch3 from end of name
            ret = strrep(name, '_ch1', '');
            ret = strrep(ret, '_ch2', '');
            ret = strrep(ret, '_ch3', '');
        end
        
        function stattype = getStatType_(obj, stat, failonerror)
        % infer which object ps.stat is in using column tokens
        % if in both, stackdb trumps int
            stattype = '';
            isStackdb = ismember(stat, obj.stackdbTokens);
            isInt = ismember(stat, obj.intTokens);
            
            % bug: assuming we have at least one stack
            userTokens = obj.userstat.Properties.VariableNames;
            isUser = ismember(stat, userTokens);

            if isStackdb
                stattype = 'stackdb';
            elseif isInt
                stattype = 'int';
            elseif isUser
                stattype = 'userstat';
            else
                errorStr = ['mywarning: ' 'mmStack.getStatType_() did not find ps.stat: `' stat '` in stack ' obj.stackName];
                if failonerror
                    error(errorStr)
                else
                    disp(errorStr)
                end
            end
        end
        
    end % methods (Hidden=true)
    
end % classdef mmStack