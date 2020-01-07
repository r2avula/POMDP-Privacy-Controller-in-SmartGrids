function [events, times] = get_events_of_single_phase_applianceNew( adversary_Params,evaluationDates,batteryConsumption)
  
    events = [];
    times = [];
    appliancePhase = adversary_Params.appliancePhase;
    dataset = adversary_Params.dataset;
    houseIndex = adversary_Params.houseIndex;
    slotIntervalInSeconds = adversary_Params.slotIntervalInSeconds;
    filteringMethod = adversary_Params.filteringMethod;
    filtLength = adversary_Params.filtLength;
    edgeThreshold = 1*adversary_Params.filtLength;
    plevelMinLength = adversary_Params.plevelMinLength;
    maxEventDuration = adversary_Params.maxEventDuration;
    eventThreshold = adversary_Params.eventThreshold;
    path_to_data = adversary_Params.path_to_data;
    
    testEvaluationHourIndexBoundaries = adversary_Params.testEvaluationHourIndexBoundaries;
    testEvaluationStart_slotIndex_in_day = adversary_Params.testEvaluationStart_slotIndex_in_day;
    testEvaluationEnd_slotIndex_in_day = adversary_Params.testEvaluationEnd_slotIndex_in_day;
    evaluation_interval = testEvaluationStart_slotIndex_in_day+1:testEvaluationEnd_slotIndex_in_day;
    
    batteryConsumption_vec = reshape(batteryConsumption(:,evaluation_interval)',1,[]);

    % get real, apparent and reactive (distortive and translative
    % component) power
    power = getModifiedPowerNew(batteryConsumption_vec,path_to_data,testEvaluationHourIndexBoundaries,dataset, houseIndex, evaluationDates, slotIntervalInSeconds, appliancePhase);

    % apply filter to normalized apparent power and get edges 
    function_handle = str2func(filteringMethod);
    normalized_apparent_power_filtered = function_handle(power.normalized_apparent, filtLength);
    [rows, cols] = find(abs(diff(normalized_apparent_power_filtered)) > edgeThreshold);
    edges = sparse(rows, cols, ones(length(rows),1), 1, size(normalized_apparent_power_filtered,2)-1);

    % get power levels (period between two edges with similar power values)
    [plevel] = getPowerLevelsStartAndEndTimes(edges, plevelMinLength);       
    if isempty(plevel.startidx)
        return;
    end

    % get characteristics of power levels
    plevel = getPowerLevelProperties(plevel, power, plevelMinLength);

    % generate event vectors by taking the diffference between two consecutive power levels
    event_vecs = zeros(length(plevel.startidx)-1, 4);
    eventIsValid = zeros(length(plevel.startidx), 1);
    numOfEvents = 0;
    for i = 1:length(plevel.startidx)-1
           if abs(plevel.mean.end(i,1) - plevel.mean.start(i+1,1)) > eventThreshold && plevel.startidx(i+1) - plevel.endidx(i) < maxEventDuration
                eventIsValid(i) = 1;
                numOfEvents = numOfEvents + 1;
                event_vecs(numOfEvents, 1:3) = plevel.mean.start(i+1, :)-plevel.mean.end(i, :);
                max_std_true_power = max(plevel.std(i,1), plevel.std(i+1,1));
                max_std_reactive_power = max(plevel.std(i,2), plevel.std(i+1,2));
                oscillationTerm = norm([max_std_true_power, max_std_reactive_power]);
                event_vecs(numOfEvents, 4) = oscillationTerm;
           end
    end
    event_vecs = event_vecs(1:numOfEvents, :);
    timeOfEvents = plevel.endidx(eventIsValid==1)'; 

    events = event_vecs;
    times = timeOfEvents;
end