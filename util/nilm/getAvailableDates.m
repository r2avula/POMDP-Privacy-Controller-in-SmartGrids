function [dates] = getAvailableDates(path_to_data,evaluation_time,house,applianceID, maxNumOfDays,missingValuesThresholdSM, missingValuesThresholdPlug, dataset)

startDate = '2012-06-01';
endDate = '2013-01-31';

testParams_ = struct;
fileNamePrefix = 'cache/availableDates_';
testParams_.startDate = startDate;
testParams_.endDate = endDate;
testParams_.evaluation_time = evaluation_time;
testParams_.house = house;
testParams_.applianceID = applianceID;
testParams_.maxNumOfDays = maxNumOfDays;
testParams_.missingValuesThresholdSM = missingValuesThresholdSM;
testParams_.missingValuesThresholdPlug = missingValuesThresholdPlug;
testParams_.dataset = dataset;
[filename,fileExists] = findFileName(testParams_,fileNamePrefix,'testParams_');
if(fileExists)
    load(filename,'dates');
else    
    house_str = num2str(house, '%02d');
    start_date_num = datenum(startDate, 'yyyy-mm-dd');
    end_date_num = datenum(endDate, 'yyyy-mm-dd');
    dates_strs = datestr(start_date_num:end_date_num, 'yyyy-mm-dd');
    day_idx = 1;
    num_of_days_selected = 0;
    num_days = size(dates_strs, 1);
    idx_of_selected_days = zeros(1,maxNumOfDays);
    
    while(num_of_days_selected < maxNumOfDays && day_idx <= num_days)
        day_is_valid = 1;
        filename_sm = [path_to_data filesep dataset filesep 'smartmeter' filesep house_str filesep dates_strs(day_idx,:) '.mat'];
        if exist(filename_sm, 'file')
            sm_consumption = read_smartmeter_dataNew(path_to_data,evaluation_time,dataset, house, dates_strs(day_idx, :), 1 , 'powerallphases');
            num_of_missing_values_in_sm = nnz(sm_consumption == -1);
            if num_of_missing_values_in_sm / length(sm_consumption) > missingValuesThresholdSM
                day_is_valid = 0;
            elseif nnz(mod(sm_consumption, 10)) < 1000
                day_is_valid = 0;
            else
                plug_str = getPlugNr(applianceID, house, dataset);
                filename_plug = [path_to_data filesep dataset filesep 'plugs' filesep house_str filesep plug_str filesep dates_strs(day_idx,:) '.mat'];
                if exist(filename_plug, 'file')
                    plug_consumption = read_plug_dataNew(path_to_data,evaluation_time,dataset, house, applianceID, dates_strs(day_idx, :), 1 );
                    num_of_missing_values_in_plug = nnz(plug_consumption == -1);
                    if num_of_missing_values_in_plug / length(plug_consumption) > missingValuesThresholdPlug
                        day_is_valid = 0;
                    end
                    num_of_pos_values_in_plug = nnz(plug_consumption > mean(plug_consumption));
                    if(sum(num_of_pos_values_in_plug) == 0)
                        day_is_valid = 0;
                    end
                    if(max(plug_consumption)< getThresholdDiffOnOff(applianceID))
                        day_is_valid = 0;
                    end
                else
                    day_is_valid = 0;
                end
            end
        else
            day_is_valid = 0;
        end
        if day_is_valid == 1
            num_of_days_selected = num_of_days_selected + 1;
            idx_of_selected_days(1, num_of_days_selected) = day_idx;
        end
        day_idx = day_idx + 1;
    end
    
    idx_of_selected_days = idx_of_selected_days(1,1:num_of_days_selected);
    dates = dates_strs(idx_of_selected_days, :);
    save(filename, 'dates','testParams_');
end
end

