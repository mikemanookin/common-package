function r = getRebounds(peaksInd, trace, searchInterval)
    % Gets rebound as fraction of peak amplitude.

    %trace = abs(trace);
    peaks = trace(peaksInd);
    r = zeros(size(peaks));

    for i=1:length(peaks)
       endPoint = min(peaksInd(i)+searchInterval, length(trace));
       nextMin = common.util.getPeaks(trace(peaksInd(i):endPoint), -1);
       if isempty(nextMin)
           nextMin = peaks(i); 
       else
           nextMin = nextMin(1); 
       end
       nextMax = common.util.getPeaks(trace(peaksInd(i):endPoint), 1);
       if isempty(nextMax)
           nextMax = 0; 
       else
           nextMax = nextMax(1);
       end

       if nextMin < peaks(i) % not the real spike min
           r(i) = 0;
       else
           r(i) = nextMax; 
       end
    end
end
