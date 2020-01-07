function [consumption_req] = read_smartmeter_dataNew(path_to_data,evaluation_time,dataset, house, dates_strs, granularity, option)
    evaluation_time = (strsplit(cell2mat(evaluation_time)));
    evaluation_time_start = str2num(cell2mat(evaluation_time(1)))*60 * 60 / granularity;
    evaluation_time_end = str2num(cell2mat(evaluation_time(2)))*60 * 60 / granularity;
    evaluation_interval_length = (evaluation_time_end-evaluation_time_start);
    
    houseStr = num2str(house, '%02d');
    result = zeros(1, size(dates_strs,1)*(24 * 60 * 60) / granularity);
    consumption_req = zeros(1, size(dates_strs,1) * (evaluation_interval_length));
    offset = 1;
    offset2 = 1;
    for day=1:size(dates_strs,1)
        filename_sm = [path_to_data filesep dataset filesep 'smartmeter' filesep houseStr filesep dates_strs(day,:) '.mat'];
        % Smartmeter data
        if exist(filename_sm, 'file')
            vars = whos('-file',filename_sm);
            load(filename_sm);
            eval(['smartmeter_data=' vars.name ';']);
            eval(['clear ' vars.name ';']);
            if (granularity > 1)
                 % powerallphases
                 eval(strcat('[mat,padded] = vec2mat(smartmeter_data.',option, ',', num2str(granularity),');'));
                 assert(padded == 0, [num2str(granularity), ' is not a permissable interval (does not divide into 24h)']);
                 result(1,offset:offset + (24 * 60 * 60)/granularity -1) = mean(mat, 2);            
            else
                 eval(strcat('result(1,offset:offset + (24 * 60 * 60)/granularity -1) = smartmeter_data.',option,';')); 
            end
        else
            result(1,offset:offset + (24 * 60 * 60)/granularity -1) = -1;
        end
        consumption_req(1,offset2:offset2 + evaluation_interval_length-1) = result(1,offset+evaluation_time_start:offset + evaluation_time_start+ evaluation_interval_length-1);
        offset2 = offset2 + evaluation_interval_length;
        offset = offset + (24 * 60 * 60) / granularity;
    end
    consumption_req = max(consumption_req,0);
end
