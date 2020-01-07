function [plevel] = getPowerLevelProperties(plevel, power, plevelMinLength)

    % get characteristics of power levels: 
    %
    % componentwise (real, reactive and distortive power) mean of the first and the last 
    % plevelMinLength values of a power level)
    
    plevel.mean.start = zeros(length(plevel.startidx), 3);
    plevel.mean.end = zeros(length(plevel.startidx), 3);
    plevel.std = zeros(length(plevel.startidx), 2);
    for i = 1:length(plevel.startidx)
        plevel.mean.start(i,1) = mean(power.real(plevel.startidx(i) : plevel.startidx(i) + plevelMinLength));
        plevel.mean.end(i,1) = mean(power.real(plevel.endidx(i) - plevelMinLength : plevel.endidx(i))); 
        plevel.mean.start(i,2) = mean(power.reactive(plevel.startidx(i) : plevel.startidx(i) + plevelMinLength));
        plevel.mean.end(i,2) = mean(power.reactive(plevel.endidx(i) - plevelMinLength : plevel.endidx(i)));   
        plevel.mean.start(i,3) = mean(power.reactive_distortive(plevel.startidx(i) : plevel.startidx(i) + plevelMinLength));
        plevel.mean.end(i,3) = mean(power.reactive_distortive(plevel.endidx(i) - plevelMinLength : plevel.endidx(i)));        
        plevel.std(i,1) = std(power.real(plevel.startidx(i):plevel.endidx(i)));
        plevel.std(i,2) = std(power.reactive(plevel.startidx(i):plevel.endidx(i)));
    end

end

