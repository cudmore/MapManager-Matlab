function plotMaxProject(obj, channel, stacksegment, showAnnotations, showLines)

    if isempty(showAnnotations)
        showAnnotations = true;
    end
    if isempty(showLines)
        showLines = true;
    end
    
    if isempty(obj.images{channel})
        obj.loadStack(channel);
    end
    
    maxImage = max(obj.images{channel}, [], 3);
    maxInt = max(maxImage(:)); % maximum intensity (scalar)

    if showAnnotations
        ps = mmMap.defaultPlotStruct();
        ps.stacksegment = stacksegment;
        ps.stat = 'x';
        xps = obj.getStackValues(ps);
        ps.stat = 'y';
        yps = obj.getStackValues(ps);
    end
    
    px = size(obj.images{channel},2); % pixels
    py = size(obj.images{channel},1); % pixels
    imageWidth = px * obj.vx;
    imageHeight = py * obj.vy;
    
    % RI is a 'spatial referencing object', sounds fancy
    RI = imref2d(size(maxImage));
    RI.XWorldLimits = [0 imageWidth-obj.vx];
    RI.YWorldLimits = [0 imageHeight-obj.vy];
    
    imshow(maxImage, RI, [0 maxInt]);
    xlabel('\mum')
    ylabel('\mum')
    
    if showAnnotations
        hold on;
        plot(xps.val, yps.val, '.b', 'MarkerSize', 20);
    end
    
    if showLines
        hold on;
        tracing = obj.getTracing(stacksegment);
        plot(tracing(:,1), tracing(:,2), '.m', 'MarkerSize', 5);
    end
    
    hold off;
end