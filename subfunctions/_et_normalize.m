function outData = et_normalize(data)
%ETNORMALIZE Return segments normalized to their own means
%   Detailed explanation goes here

arguments (Input, Repeating)
    data
end
% arguments (Output)
%     outData cell
% end
arguments (Output, Repeating)
    outData
end

outData = cell(size(data));
nData = size(data, 2);

for d = 1:nData
    currSeg = data{d};
    szCurrSeg = size(currSeg);
    %meanY = zeros(szCurrSeg);
    %dblNormY = cell(size(currSeg));
    tblNormY = currSeg;
    
    if szCurrSeg(2) ~= 2
        error('Input #%d may not be eye block, nCols==%d...?', d, szCurrSeg(2));
    end
    if szCurrSeg(1) == 1
        % Is dot or rest
        b = 1;
        for e = 1:2
            tblNormY{b,e}.y_avg = currSeg{b,e}.y_avg ./ mean(currSeg{b,e}.y_avg);            
            %outData{e} = currSeg{e}.y_avg ./ meanY(e);
        end
    elseif szCurrSeg(1) == 2
        error('Input #%d has nRows == %d. Is this correct?', d, szCurrSeg(1));
    elseif szCurrSeg(1) == 3
        % Is wait
        for e = 1:2
            for b = 1:szCurrSeg(1)        
                tblNormY{b,e}.y_avg = currSeg{b,e}.y_avg ./ mean(currSeg{b,e}.y_avg);
                %outData{e} = currSeg{b,e}./meanY(b,e);
            end
        end
    else
    end
    %tblNormY{b,e}.y_avg = dblNormY;
    outData{d} = tblNormY;
end

end

