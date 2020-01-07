function [consumption_req] = read_plug_dataNew(path_to_data,evaluation_time,dataset, house, appliance, dates_strs, granularity)
household = num2str(house, '%02d');
plug = getPlugNr(appliance, house, dataset);
consumption_day = zeros(1, size(dates_strs,1) * (24 * 60 * 60) / granularity);
evaluation_time = (strsplit(cell2mat(evaluation_time)));
evaluation_time_start = str2num(cell2mat(evaluation_time(1)))*60 * 60 / granularity;
evaluation_time_end = str2num(cell2mat(evaluation_time(2)))*60 * 60 / granularity;
evaluation_interval_length = (evaluation_time_end-evaluation_time_start);
consumption_req = zeros(1, size(dates_strs,1)*evaluation_interval_length );
offset = 1;
offset2 = 1;
for day=1:size(dates_strs,1)
    filename_plug = [path_to_data filesep dataset filesep 'plugs' filesep household filesep plug filesep dates_strs(day,:) '.mat'];
    if exist(filename_plug, 'file')
        vars = whos('-file',filename_plug);
        load(filename_plug);
        eval(['smartmeter_data=' vars.name ';']);
        eval(['clear ' vars.name ';']);
        if (granularity > 1)
            [mat,padded] = vec2mat(smartmeter_data.consumption,granularity);
            assert(padded == 0, [num2str(granularity), ' is not a permissable interval (does not divide into 24h)']);
            consumption_day(1,offset:offset + (24 * 60 * 60) / granularity -1) = mean(mat, 2);
        else
            consumption_day(1,offset:offset + (24 * 60 * 60) / granularity -1) = smartmeter_data.consumption;
        end
    else
        consumption_day(1,offset:offset + (24 * 60 * 60) / granularity -1) = -1;
    end
    
    consumption_req(1,offset2:offset2 + evaluation_interval_length-1) = consumption_day(1,offset+evaluation_time_start:offset + evaluation_time_start+ evaluation_interval_length-1);
    offset = offset + (24 * 60 * 60) / granularity;
    offset2 = offset2 + evaluation_interval_length;
end
consumption_req = max(consumption_req,0);
end
