% Robert Cudmore
% 20171007

function plotMaxProject(obj,ps, showAnnotations, showLines)

    ps = obj.LoadStacks(ps);
    
    maxImage = max(ps.images{ps.session}, [], 3);
    maxInt = max(maxImage(:));

    if showAnnotations
        ps.stat = 'x';
        xps = obj.GetMapValues(ps);
        ps.stat = 'y';
        yps = obj.GetMapValues(ps);
    end
    
    dx = obj.GetValue_NV('dx',ps.session); % um/pixel
    px = obj.GetValue_NV('px',ps.session); % pixels
    %todo: fix this, make GetValue_NV() actually return a value
    dx = str2num(dx);
    px = str2num(px);
    imageWidth = px * dx;
    imageHeight = px * dx;
    
    % RI is a 'spatial referencing object', sounds fancy
    RI = imref2d(size(maxImage));
    RI.XWorldLimits = [0 imageWidth-dx];
    RI.YWorldLimits = [0 imageHeight-dx];
    
    imshow(maxImage, RI, [0 maxInt]);
    xlabel('\mum');
    ylabel('\mum');
    
    if showAnnotations
        hold on;
        % todo: make GetMapValues return session vector if ps.session ~= nan
        plot(xps.y(:,ps.session), yps.y(:,ps.session), '.b', 'MarkerSize', 20);
    end
    
    if showLines
        hold on;
        line_ps = obj.GetLine(ps);
        plot(line_ps.line(:,1), line_ps.line(:,2), '.m', 'MarkerSize', 5);
    end
    
    hold off;
end