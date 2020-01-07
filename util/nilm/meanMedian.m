function [data_mean_median_filtered] = meanMedian(data, filterLength)

    % first apply mean filter and subsequently, apply median filter

    data_mean_median_filtered = zeros(size(data));
    for i = 1:size(data,1)
        
        if rem(filterLength,2) == 0   
            m = filterLength/2;
        else
            m = (filterLength-1)/2;
        end
        paddingStart = ones(1,m)*data(i,1);
        paddingEnd = ones(1,m)*data(i,end);
        x = [paddingStart, data(i,:), paddingEnd];
        data_mean_filtered = filter(ones(1,filterLength)./filterLength,1, x);
        data_mean_filtered = data_mean_filtered(2*m+1:end);
        data_mean_median_filtered(i,:) = medfilt1(data_mean_filtered, filterLength);
    end

end

