clear;
path_to_data = simStartup();

adversary_config_filename = 'kettle_usage_test_house_2_1minute_weiss.yaml';
adversary_config = ReadYaml(adversary_config_filename);
adversary_config.path_to_data = path_to_data;
availableData_adversary = fetchData(adversary_config);

trainingDaysCount_adversary = adversary_config.trainingDaysCount;
trainingDates_adversary = availableData_adversary.availableDates(1:trainingDaysCount_adversary,:);
adversary_Params = initAdversaryParams(adversary_config,trainingDates_adversary);

controller_config_filename = 'pomdp_control_kettle_usage_house_2_1minute.yaml';
controller_config = ReadYaml(controller_config_filename);
controller_config.path_to_data = path_to_data;
availableData_controller = fetchData(controller_config);

trainingDaysCount_controller = controller_config.trainingDaysCount;
trainingData_controller = availableData_controller.appliance_consumption(1:trainingDaysCount_controller,:);
[controller_Params] = initControllerParams(controller_config,trainingData_controller);
controlPolicyFilename = findControlPolicy(controller_Params);
controller_Params.controlPolicy = load(controlPolicyFilename);

evaluationDaysCount = 30;
initSoCValues = [0 0.25 0.5 0.75 0.9 1];

evalCacheParams = struct;
evalCacheParams.adversary_Params = adversary_Params;
evalCacheParams.controller_Params = controller_Params;
evalCacheParams.evaluationDaysCount = evaluationDaysCount;
evalCacheParams.initSoCValues = initSoCValues;
fileNamePrefix = strcat('cache/evaluationData_');

[filename,fileExists] = findFileName(evalCacheParams,fileNamePrefix,'evalCacheParams');
if fileExists
    load(filename,'fscore','energyLoss','ambr','ambr_adversary');
    disp(strcat({'evaluationData loaded from '},filename,' .'));
else
    numCases = length(initSoCValues) +1;
    fscore = zeros(evaluationDaysCount,numCases);
    energyLoss = zeros(evaluationDaysCount,numCases);
    ambr = zeros(evaluationDaysCount,numCases);
    ambr_adversary = zeros(evaluationDaysCount,numCases);
    
    for evalDayIdx = 1:evaluationDaysCount
        evaluationDayOffset = -(evalDayIdx-1);
        evaluationDateRange = (trainingDaysCount_controller+1+evaluationDayOffset);
        evaluationData_appliance = availableData_controller.appliance_consumption(evaluationDateRange,:);
        evaluationData_sm = availableData_controller.sm_consumption(evaluationDateRange,:);
        evaluationDates = availableData_controller.availableDates(evaluationDateRange,:);
        
        %% with controller
        for caseIdx = 1:numCases-1
            [simulatedControllerData] = simulate_pomdp_controller(controller_Params,evaluationData_appliance,evaluationData_sm,initSoCValues(caseIdx));
            batteryConsumption = simulatedControllerData.battery_consumption_whole_day;
            recognizedEvents = simulate_nilm_adversary(adversary_Params,evaluationDates,batteryConsumption);
            fscore(evalDayIdx,caseIdx) = calculate_performance_eventsNew(controller_Params, evaluationData_appliance, recognizedEvents);
            energyLoss(evalDayIdx,caseIdx) = simulatedControllerData.totalEnergyLoss;
            ambr(evalDayIdx,caseIdx) = simulatedControllerData.ambr;
            ambr_adversary(evalDayIdx,caseIdx) = simulatedControllerData.ambr_adversary;
        end
        %% without controller
        caseIdx = numCases;
        batteryConsumption = zeros(size(evaluationData_sm));
        recognizedEvents = simulate_nilm_adversary(adversary_Params,evaluationDates,batteryConsumption);
        fscore(evalDayIdx,caseIdx) = calculate_performance_eventsNew(controller_Params, evaluationData_appliance, recognizedEvents);
        disp(evalDayIdx)
    end
    
    save(filename,'fscore','energyLoss','ambr','ambr_adversary','evalCacheParams');
    disp(strcat({'evaluationData saved to '},filename,' .'));
end

average_fscore = mean(fscore,1);
average_energyLoss = mean(energyLoss,1);
average_ambr = mean(ambr,1);
average_ambr_adversary = mean(ambr_adversary,1); % There is an erronous 7.5 scaling factor in the AMBR results presented in paper
