% Robert Cudmore
% 20171007
%
% Each spine annotation stackdb(i,'pDist') gives distance in um
% along segment tracing

% todo: This is assuming all segments are connected 0,1,2,...
%   need to add this to GetMapValues()

function [retVal,retVec] = segmentanalysis(theMap, theStat, theChannel, f)
    
    ps = theMap.defaultPlotStruct();
    ps.stat = theStat;
    ps.channel = theChannel;
    
    ret = nan(theMap.numMapSegments, theMap.numSessions);
    for i = 1:theMap.numMapSegments
        ps.mapsegment = i;
        
        ps = theMap.GetMapValues(ps); % user specified stat (theStat)
        
        pDist_ps = ps;
        pDist_ps.stat = 'pDist';
        pDist_ps = theMap.GetMapValues(pDist_ps); % pDist

        for j = 1:theMap.numSessions
            stackdbSegment = theMap.segmentRunMap(i,j);
            if isnan(stackdbSegment)
                continue
            end
                        
            % get values for theStat at segment i, session j
            
            % this would go in a user function following prototype signature
            % get distance/position along the traced segment
            %vals = pDist_ps.y(:,j);
            %vals = vals(~isnan(vals));
            %[sortedVals, sortedOrder] = sort(vals); % sort by pDist
            
            %
            % analysis for each segment
            [retVal(i,j), retVec(i,j)] = f(theMap, j, i, ps.val(:,j), pDist_ps.val(:,j));
            
            % put retVec back into a run matrix
            
        end % j numSessions
    end % i numMapSegments
end