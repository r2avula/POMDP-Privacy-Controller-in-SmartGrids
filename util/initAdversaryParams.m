function [params] = initAdversaryParams(config,trainingDates)
slotIntervalInSeconds = config.slotIntervalInSeconds;
testEvaluationHourIndexBoundaries = (config.testEvaluationHourIndexBoundaries);
testEvaluationHourIndexBoundaries = (strsplit(cell2mat(testEvaluationHourIndexBoundaries)));
testEvaluationStart_slotIndex_in_day = str2double(cell2mat(testEvaluationHourIndexBoundaries(1)))*3600/ slotIntervalInSeconds;
testEvaluationEnd_slotIndex_in_day = str2double(cell2mat(testEvaluationHourIndexBoundaries(2)))*3600 / slotIntervalInSeconds;

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

path_to_data = config.path_to_data;
detectionAlgorithm = config.detectionAlgorithm;
if(isequal(detectionAlgorithm,'weiss'))
    fileNamePrefix = 'cache/signatureDB_';
    signatureDBParams = struct;
    signatureDBParams.dataset = config.dataset;
    signatureDBParams.houseIndex = config.houseIndex;
    signatureDBParams.slotIntervalInSeconds = config.slotIntervalInSeconds;
    signatureDBParams.filteringMethod = config.filteringMethod;
    signatureDBParams.filtLength = config.filtLength;
    signatureDBParams.plevelMinLength = config.plevelMinLength;
    signatureDBParams.maxEventDuration = config.maxEventDuration;
    signatureDBParams.testEvaluationHourIndexBoundaries = (config.testEvaluationHourIndexBoundaries);
    signatureDBParams.edgeThreshold = config.filtLength;
    signatureDBParams.testAppliances = config.testAppliances;    
    signatureDBParams.trainingDates = trainingDates;
    [filename,fileExists] = findFileName(signatureDBParams,fileNamePrefix,'signatureDBParams');
    if(fileExists)
        load(filename,'signature_database');
    else        
        signature_database = buildSignatureDatabase(config, trainingDates);
        save(filename,'signature_database','signatureDBParams');
    end
else
    error('Not yet implemented!');
end
appliancePhase = getPhase(houseIndex, applianceID, dataset);

% Prepare adversary params
params = struct;
params.slotIntervalInSeconds = slotIntervalInSeconds;
params.testEvaluationHourIndexBoundaries = config.testEvaluationHourIndexBoundaries;
params.testEvaluationStart_slotIndex_in_day = testEvaluationStart_slotIndex_in_day;
params.testEvaluationEnd_slotIndex_in_day = testEvaluationEnd_slotIndex_in_day;
params.appliance_name = appliance_name;
params.applianceID = applianceID;
params.appliancePhase = appliancePhase;
params.dataset = dataset;
params.houseIndex = houseIndex;
params.trainingDates = trainingDates;
params.path_to_data = path_to_data;
params.detectionAlgorithm = detectionAlgorithm;
params.signature_database = signature_database;
params.filteringMethod = config.filteringMethod;
params.filtLength = config.filtLength;
params.plevelMinLength = config.plevelMinLength;
params.maxEventDuration = config.maxEventDuration;
params.eventThreshold = config.eventThreshold;
params.filteringMethod = config.filteringMethod;
params.r = config.r;
params.osc = config.osc;
end