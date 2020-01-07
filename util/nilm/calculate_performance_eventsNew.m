function [fscore] = calculate_performance_eventsNew(controller_Params, evaluationData_appliance, recognizedEvents)

% compute performance regarding the inferred events
testEvaluationStart_slotIndex_in_day = controller_Params.testEvaluationStart_slotIndex_in_day; 
testEvaluationEnd_slotIndex_in_day = controller_Params.testEvaluationEnd_slotIndex_in_day; 
evaluation_interval = testEvaluationStart_slotIndex_in_day+1:testEvaluationEnd_slotIndex_in_day;

p_filtering = controller_Params.p_filtering;
p_filtLength = controller_Params.p_filtLength;

% get ground truth from plug-level data
ground_truth_events = [];
applianceID = controller_Params.applianceID;

% detect events in plug data
evaluationData_appliance_vec = reshape(evaluationData_appliance(:,evaluation_interval)',1,[]);

function_handle = str2func(p_filtering);
appliance_consumption_filtered = function_handle(evaluationData_appliance_vec, p_filtLength);
diff_consumption = diff(appliance_consumption_filtered);
edges = abs(diff_consumption) > p_filtLength;
events_start_time = find(diff(edges) == 1) + 1;
events_end_time = find(diff(edges) == -1) + 1;

% make sure that the events' end and start time are correct
if events_end_time(1) < events_start_time(1)
    events_end_time = events_end_time(2:end);
end
if events_end_time(end) < events_start_time(end)
    events_start_time = events_start_time(1:end-1);
end

% compute change in power caused by events
power_change = appliance_consumption_filtered(1, events_end_time) - appliance_consumption_filtered(1, events_start_time);

% ignore events that last too long ( > 60 seconds)
idx_valid_events = events_end_time - events_start_time < 60;

% store the ground truth (events in plug data)
ground_truth_events = [ground_truth_events; events_start_time(idx_valid_events)', events_end_time(idx_valid_events)', power_change(idx_valid_events)', applianceID*ones(length(events_start_time(idx_valid_events)), 1)];

% compute performance metrics for each appliance
idx_ground_truth_events = ground_truth_events(:,4) == applianceID;
if(~isempty(recognizedEvents))
    idx_inferred_events = find(recognizedEvents(:,2) == applianceID);
    ind_ground_truth_events = find(idx_ground_truth_events);
    vec = arrayfun(@(t) any(ground_truth_events(idx_ground_truth_events,1) - 5 < t & t < ground_truth_events(idx_ground_truth_events,2) + 5),...
        recognizedEvents(idx_inferred_events, 1));
    vec2 = arrayfun(@(id) any(ground_truth_events(id,1) - 5 < recognizedEvents(idx_inferred_events, 1) & ...
        recognizedEvents(idx_inferred_events, 1) < ground_truth_events(id,2) + 5), ind_ground_truth_events);
    tp = nnz(vec);
    fp = nnz(~vec);
    fn = nnz(~vec2);
else
    [m,~] = size(idx_ground_truth_events);
    tp = 0;
    fp = 0;
    fn = m;
end

% compute f-score, precision and recall
if tp + fp == 0
    precision = 0;
else
    precision = tp / (tp + fp);
end
if (tp + fn) == 0
    recall = 0;
else
    recall = tp / (tp + fn);
end
if precision + recall == 0
    fscore = 0;
else
    fscore = 2* precision * recall /(precision + recall);
end
end

