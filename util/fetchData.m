function [availableData] = fetchData(config)

slotIntervalInSeconds = config.slotIntervalInSeconds;
testAppliances = (config.testAppliances);
if(length(testAppliances)>1)
    error('Not implemented for more than one appliance!');
end
appliance_name = cell2mat(testAppliances(1));
applianceID = getApplianceID(appliance_name);

dataset = config.dataset;
houseIndex = config.houseIndex;
if(iscell(houseIndex))
    houseIndex =  cell2mat(houseIndex);
    if(length(houseIndex)>1)
        error('Not implemented for more than one house!');
    end
end

maxNumOfDays = config.maxNumOfDays;
missingValuesThresholdSM = config.missingValuesThresholdSM; 
missingValuesThresholdPlug = config.missingValuesThresholdPlug;

path_to_data = config.path_to_data;
availableDates = getAvailableDates(path_to_data,config.testEvaluationHourIndexBoundaries,houseIndex,applianceID, maxNumOfDays, missingValuesThresholdSM, missingValuesThresholdPlug, dataset);

fileNamePrefix = 'cache/smartMeterData_';
smDataParams = struct;
smDataParams.dataset = dataset;
smDataParams.slotIntervalInSeconds = slotIntervalInSeconds;
smDataParams.houseIndex = houseIndex;
smDataParams.availableDates = availableDates;

[filename,fileExists] = findFileName(smDataParams,fileNamePrefix,'smDataParams');
if(fileExists)
    load(filename,'sm_consumption');
else        
    availableDays = size(availableDates,1);
    sm_consumption = zeros(availableDays,24*3600/slotIntervalInSeconds);
    for dayIdx = 1:availableDays
        sm_consumption(dayIdx,:) = read_smartmeter_dataNew(path_to_data,cellstr('0 24'),dataset, houseIndex, availableDates(dayIdx,:), slotIntervalInSeconds , 'powerallphases');
    end
    save(filename,'sm_consumption','smDataParams');
end

fileNamePrefix = 'cache/applianceData_';
appDataParams = struct;
appDataParams.dataset = dataset;
appDataParams.slotIntervalInSeconds = slotIntervalInSeconds;
appDataParams.houseIndex = houseIndex;
appDataParams.availableDates = availableDates;
appDataParams.testEvaluationHourIndexBoundaries = config.testEvaluationHourIndexBoundaries;
appDataParams.applianceID = applianceID;

[filename,fileExists] = findFileName(appDataParams,fileNamePrefix,'appDataParams');
if(fileExists)
    load(filename,'appliance_consumption');
else            
    availableDays = size(availableDates,1);
    appliance_consumption = zeros(availableDays,24*3600/slotIntervalInSeconds);
    for dayIdx = 1:availableDays
        appliance_consumption(dayIdx,:) = read_plug_dataNew(path_to_data,cellstr('0 24'),dataset, houseIndex, applianceID, availableDates(dayIdx,:), slotIntervalInSeconds);
    end    
    save(filename,'appliance_consumption','appDataParams');
end

availableData = struct;
availableData.availableDates = availableDates;
availableData.sm_consumption = sm_consumption;
availableData.appliance_consumption = appliance_consumption;
end

