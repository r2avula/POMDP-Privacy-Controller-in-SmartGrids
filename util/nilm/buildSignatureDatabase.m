function [sig_database] = buildSignatureDatabase(config, trainingDates)

% load parameters of algorithm
dataset = config.dataset;
houseIndex = config.houseIndex;
if(iscell(houseIndex))
    houseIndex =  cell2mat(houseIndex);
    if(length(houseIndex)>1)
        error('Not implemented for more than one house!');
    end
end
slotIntervalInSeconds = config.slotIntervalInSeconds;
filteringMethod = config.filteringMethod;
filtLength = config.filtLength;
plevelMinLength = config.plevelMinLength;
maxEventDuration = config.maxEventDuration;
path_to_data = config.path_to_data;

testEvaluationHourIndexBoundaries = (config.testEvaluationHourIndexBoundaries);

% set variables
edgeThreshold = config.filtLength;

sig_database = struct;
numOfSignatures = 1;

% get appliance consumption
testAppliances = config.testAppliances;
if(length(testAppliances)>1)
    error('Not implemented for more than one appliance!');
end
appliance_name = cell2mat(testAppliances(1));
applianceID = getApplianceID(appliance_name);
phase = getPhase(houseIndex, applianceID, dataset);

% get real, apparent and reactive (distortive and translative
% component) power
power = getPowerNew(path_to_data,testEvaluationHourIndexBoundaries,dataset, houseIndex, trainingDates, slotIntervalInSeconds, phase);
appliance_consumption = read_plug_dataNew(path_to_data,testEvaluationHourIndexBoundaries,dataset, houseIndex, applianceID, trainingDates, slotIntervalInSeconds);

function_handle = str2func(filteringMethod);
appliance_consumption_filtered = function_handle(appliance_consumption, filtLength);
[rows, cols] = find(abs(diff(appliance_consumption_filtered)) > edgeThreshold);
edges = sparse(rows, cols, ones(length(rows),1), 1, size(appliance_consumption,2)-1);

% get power levels (period between two edges with similar power values)
[plevel] = getPowerLevelsStartAndEndTimes(edges, plevelMinLength);
if isempty(plevel.startidx)
    return;
end

% get componentwise(true power, reactive power, distortive power) start and end mean of each selected power level
plevel = getPowerLevelProperties(plevel, power, plevelMinLength);

% extract events (between two power levels)
event_vecs = zeros(length(plevel.startidx)-1, 3);
numOfEvents = 0;
threshold_diff_on_off = getThresholdDiffOnOff(applianceID);
total_length = length(plevel.startidx);
logic1_length = 0;
logic2_length = 0;
for i = 1:length(plevel.startidx)-1
    logic_1 = abs(plevel.mean.end(i,1) - plevel.mean.start(i+1,1)) > threshold_diff_on_off;
    logic_2 = plevel.startidx(i+1) - plevel.endidx(i) < maxEventDuration;
    if  logic_1 && logic_2
        %                 if  logic_1
        numOfEvents = numOfEvents + 1;
        event_vecs(numOfEvents, :) = plevel.mean.start(i+1, 1:3)-plevel.mean.end(i, 1:3);
    end
    if(logic_1)
        logic1_length = logic1_length +1;
    end
    if(logic_2)
        logic2_length = logic2_length +1;
    end
end
event_vecs = event_vecs(1:numOfEvents, :);

% build mean of positive and negative difference vectors, remove outliers first
idx_neg = event_vecs(:,1) < 0;
idx_pos = event_vecs(:,1) > 0;

numOfDims = 2;
for idx = [idx_neg, idx_pos]
    bic = zeros(ceil(sqrt(nnz(idx)/2)),1);
    %bic2 = zeros(ceil(sqrt(nnz(idx)/2)),1);
    if nnz(idx) > 1
        % apply k-means clustering to positive and negative
        % events, k is selected dynamically
        for k = 1:ceil(sqrt(nnz(idx)/2))
            first_k_indexes = find(idx == 1, k, 'first');
            [~, ~, distances] = kmeans(event_vecs(idx, 1:numOfDims), k, 'emptyaction', 'singleton', 'start', event_vecs(first_k_indexes, 1:numOfDims));
            log_likelihood = -sum(distances);
            bic(k,1) = k*numOfDims*log(nnz(idx)) - 2*log_likelihood;
            %[~, bic2(k,1)] = aicbic(log_likelihood, k*numOfDims, nnz(idx));
        end
        [~, numOfClusters] = min(bic);
        first_k_indexes = find(idx == 1, numOfClusters, 'first');
        [IDX, centers, ~] = kmeans(event_vecs(idx, 1:numOfDims), numOfClusters, 'emptyaction', 'singleton', 'start', event_vecs(first_k_indexes, 1:numOfDims));
        
        % generate signatures out of the cluster centroids
        bincounts = histc(IDX, 1:numOfClusters);
        [~, sorted_idx] = sort(bincounts, 'descend');
        cluster_frequency = bincounts./sum(bincounts);
        idx_over_30_percent = cluster_frequency > 0.3;
        for i = 1:max(1,nnz(idx_over_30_percent))
            sig_database.signatures(numOfSignatures, :) = centers(sorted_idx(i),:);
            sig_database.phases(numOfSignatures, 1) = phase;
            sig_database.names{numOfSignatures} = (appliance_name);
            numOfSignatures = numOfSignatures + 1;
        end
    end
end

end

