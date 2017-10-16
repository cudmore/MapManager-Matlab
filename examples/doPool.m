% doPool()
%
% Pool a stat across maps in a list by taking mean across each spine run
% only including sessions in a list of session conditions.
%
% Usage:
%   ret = doPool(mapList, stat, channel, condList)
%
% Parameters:
%   mapList (vector of mmMap) : 
%   stat (Str) :
%   channel (int) : 
%   condList (vector of string) : 
%
% Returns:
%   ret.poolMaps (string column vector) : 
%   ret.poolVal (float matrix) : rows are ALL runs from maps in mapList.
%       Columns are each condition in condList
%   ret.poolCondNum (float matrix) : same shape as ps.poolCondNum
%
% Example:
%   myStat = 'ubssSum';
%   myChannel = 2;
%   myCondList = {'c*', 'c2', 'e*'};
%   myPool = doPool(myMapList, myStat, myChannel, myCondList)
%   plot(myPool.poolCondNum, myPool.poolVal, 'ok');

% Author: RObert Cudmore
% Date: 20171016

function ret = doPool(mapList, stat, channel, condList)

    numMaps = length(mapList);
    numCond = length(condList);
    
    ps = mmMap.defaultPlotStruct();
    ps.stat = stat;
    ps.channel = channel;

    % what we fill in
    ret.poolMaps = NaN(1,1);
    ret.poolVal = NaN(1,numCond);
    ret.poolCondNum = NaN(1,numCond);

    for i = 1:numMaps

        mapName = mapList(i).mapName;
        
        % get stat values for current map (all sessions)
        ps = mapList(i).GetMapValues(ps);
        mVal = size(ps.val,1);

        startRow = size(ret.poolVal,1);
        stopRow = startRow + mVal - 1;

        % accumulate values for pool
        ret.poolMaps(startRow:stopRow,1) = i;
        ret.poolVal(startRow:stopRow,:) = NaN;
        ret.poolCondNum(startRow:stopRow,:) = NaN;
        
        for k = 1:numCond
            currCond = condList{k};
            
            % condMean is single column of means across sessions
            % matching currCond (wildcard)
            condMean = mapList(i).GetMapValuesCond(ps, currCond);
        
            ret.poolVal(startRow:stopRow,k) = condMean(:);
            ret.poolCondNum(startRow:stopRow,k) = k;
        end
        
    end % i maps

end % doPool