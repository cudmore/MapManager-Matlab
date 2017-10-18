% Example protoype function to be passed to mmMap.segmentAnalysis(ps, f)
%   Write your own and return answers for each segment
%       retVal : A scalar or struct
%       retVec : 
%
% Example Usage:
%   % Load a map
%   myPath = '/path/to/map/manager/map/folder';
%   myMap = mmMap(myPath);
%
%   % Set up what to analyze
%   ps = mmMap.defaultPlotStruct();
%   ps.stat = 'ubssSum';
%   ps.channel = 2;
%
%   % Specify your own function
%   myFunction = 'segmentStats'; % in this example there needs to be a .m file segmentStats.m 
%
%   % call myMap.segmentAnalysis()
%   % This will call myFunction for each segment controlled by ps
%   % For example, if you specify ps.mapSegment=1 then myFunction
%   %   will be called for mapSegment 1 across all sessions.
%   % The default, ps.mapSegment=NaN will call myFunction for all segments in the map.
%
%   mySegmentStats = myMap.segmentAnalysis(ps, myFunction)
%
%   % mySegmentStats is now a (myMap.numSegments,myMap.numSessions) matrix
%   % Where mySegmentStats(i,j) is retVal returned from @segmentStats
%   %   function.
%
%   %In this example, retVal is a struct containing statistics for 'ubssSum'
%   %    for each segment.

% Author: Robert Cudmore
% Date: 20171008

% Function prototype to be passed to mmMap.segmentAnalysis f
function [retVal,retVec] = segmentStats(theMap, theSession, theMapSegment, theVals, the_pDist)
    
    retVal.mean = mean(theVals(~isnan(theVals)));
    retVal.std = std(theVals(~isnan(theVals)));
    retVal.count = sum(~isnan(theVals));
    retVal.se = retVal.std / sqrt(retVal.count-1);
    
    retVec = NaN;

    dispStr = ['   segmentStats() for map:' theMap.mapName ' session:' num2str(theSession) ' mapsegment:' num2str(theMapSegment)];
    dispStr = [dispStr ' mean:' num2str(retVal.mean) ' std:' num2str(retVal.std) ' count:' num2str(retVal.count)];
    %disp(dispStr);
end

