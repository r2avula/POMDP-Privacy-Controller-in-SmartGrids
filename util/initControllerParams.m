function [params] = initControllerParams(config,trainingData)

slotIntervalInSeconds = config.slotIntervalInSeconds;
slotIntervalInHours = slotIntervalInSeconds/3600; %in h
testEvaluationHourIndexBoundaries = (config.testEvaluationHourIndexBoundaries);
testEvaluationHourIndexBoundaries = (strsplit(cell2mat(testEvaluationHourIndexBoundaries)));
testEvaluationStart_slotIndex_in_day = str2double(cell2mat(testEvaluationHourIndexBoundaries(1)))*3600/ slotIntervalInSeconds;
testEvaluationEnd_slotIndex_in_day = str2double(cell2mat(testEvaluationHourIndexBoundaries(2)))*3600 / slotIntervalInSeconds;
evaluation_interval = testEvaluationStart_slotIndex_in_day+1:testEvaluationEnd_slotIndex_in_day;

k_num = (testEvaluationEnd_slotIndex_in_day-testEvaluationStart_slotIndex_in_day);
priorMaxPowerConstraint = config.priorMaxPowerConstraint;
if(ischar(priorMaxPowerConstraint))
    priorMaxPowerConstraint = str2double(priorMaxPowerConstraint);
end

p_max = priorMaxPowerConstraint; % in W
p_pu = config.powerQuantPU; % in W

batteryNominalVoltage = (config.batteryNominalVoltage);      % in V
batteryRatedCapacityInAh = (config.batteryRatedCapacityInAh);    % in Ah

batteryContinuousChargeCurrentMax = (config.batteryContinuousChargeCurrentMax);   % in A
batteryContinuousDischargeCurrentMax = (config.batteryContinuousDischargeCurrentMax);   % in A

e_pu = config.batteryEnergyQuantPU; % in Wh

x_max_pu = floor(p_max/p_pu);
x_min_pu = 0;
x_num = x_max_pu-x_min_pu+1;

d_ch_max_pu = round(batteryContinuousChargeCurrentMax*batteryNominalVoltage/p_pu);
d_disch_max_pu = -round(batteryContinuousDischargeCurrentMax*batteryNominalVoltage/p_pu);

z_cap = (batteryRatedCapacityInAh*batteryNominalVoltage); % in Wh
z_max_pu = round(z_cap/e_pu);
z_min_pu = 0;
z_num = z_max_pu-z_min_pu+1;

y_max_pu = x_max_pu+d_ch_max_pu;
y_min_pu = d_disch_max_pu;
y_num = y_max_pu-y_min_pu+1;

converterEfficiency = (config.converterEfficiency);   %efficiency factor
batterySelfDischargeRatePerMonth = (config.batterySelfDischargeRatePerMonth); % factor in [0,1]
tau = 30*24/-log(1-batterySelfDischargeRatePerMonth); %h
alphah = exp(-slotIntervalInHours/tau); %unitless
batteryInternalResistance = (config.batteryInternalResistance);  % in ohm
betah = batteryNominalVoltage*tau*(1-alphah)/2/batteryInternalResistance; %h


testAppliances = (config.testAppliances);
if(length(testAppliances)>1)
    error('Not implemented for more than one appliance!');
end
appliance_name = cell2mat(testAppliances(1));
applianceID = getApplianceID(appliance_name);

h_num = length(testAppliances)*2;            % Number of states of hypothesis        --|H|

trainingData_evaluationTime = trainingData(:,evaluation_interval);
trainingData_vec = reshape(trainingData_evaluationTime',[],1);
appliance_ON_powerThreshold = config.appliance_ON_powerThreshold;
[~,~,P_Hp1gH,P_H_init,P_XgH,~] = getHMMParams(trainingData_vec,appliance_ON_powerThreshold,x_num,p_pu);

%% belief space quantization
belief_space_precision = 10^(-config.beliefSpacePrecisionDigits);
belief_space_proxy_int_sum = floor(1/belief_space_precision);
belief_space_quant_points_num = belief_space_proxy_int_sum+1;
temp_dividers = nchoosek(1:(belief_space_proxy_int_sum+h_num-1), h_num-1);
prob_ndividers = size(temp_dividers, 1);
temp = cat(2, zeros(prob_ndividers, 1), temp_dividers, (belief_space_proxy_int_sum+h_num)*ones(prob_ndividers, 1));
belief_space = belief_space_precision*(diff(temp, 1, 2) - 1)';
belief_count = length(belief_space);
belief_space_hash = zeros(belief_count,1);
hash_coeffs = ones(h_num,1);
for i= h_num-1:-1:1
    hash_coeffs(i) = hash_coeffs(i+1)*belief_space_quant_points_num;
end
for i= 1:belief_count
    belief_space_hash(i)=floor(sum(hash_coeffs.*belief_space(:,i)));
end

%% Prepare battery params
batteryParams = struct;
batteryParams.batteryNominalVoltage = batteryNominalVoltage;
batteryParams.alphah = alphah;
batteryParams.betah = betah;
batteryParams.converterEfficiency = converterEfficiency;
batteryParams.e_pu = e_pu;
batteryParams.p_pu = p_pu;
batteryParams.batteryInternalResistance = batteryInternalResistance;
batteryParams.slotIntervalInHours = slotIntervalInHours;
batteryParams.z_num = z_num;

%% Prepare controller params
params = struct;
params.belief_space_precision = belief_space_precision;
params.testEvaluationStart_slotIndex_in_day = testEvaluationStart_slotIndex_in_day;
params.testEvaluationEnd_slotIndex_in_day = testEvaluationEnd_slotIndex_in_day;
params.P_Hp1gH = P_Hp1gH;
params.P_XgH = P_XgH;
params.P_H_init = P_H_init;
params.belief_space_proxy_int_sum = belief_space_proxy_int_sum;
params.batteryParams = batteryParams;
params.belief_count = belief_count;
params.belief_space = belief_space;
params.belief_space_hash = belief_space_hash;
params.h_num = h_num;
params.hash_coeffs = hash_coeffs;
params.d_ch_max_pu = d_ch_max_pu;
params.d_disch_max_pu = d_disch_max_pu;
params.x_offset = 1;
params.y_offset = 1-d_disch_max_pu;
params.z_offset = 1;
params.p_max = p_max;
params.p_pu = p_pu;
params.slotIntervalInHours = slotIntervalInHours;
params.x_num = x_num;
params.y_num = y_num;
params.z_num = z_num;
params.k_num = k_num;
params.applianceID = applianceID;
params.p_filtering = config.p_filtering;
params.p_filtLength = config.p_filtLength;
end