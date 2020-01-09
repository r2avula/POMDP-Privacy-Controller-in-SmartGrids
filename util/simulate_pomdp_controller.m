function [simulatedControllerData] = simulate_pomdp_controller(controller_Params,appliance_consumption_original,sm_consumption_original,init_soc)

testEvaluationStart_slotIndex_in_day = controller_Params.testEvaluationStart_slotIndex_in_day;
testEvaluationEnd_slotIndex_in_day = controller_Params.testEvaluationEnd_slotIndex_in_day;
evaluation_interval = testEvaluationStart_slotIndex_in_day+1:testEvaluationEnd_slotIndex_in_day;

controlPolicy  = controller_Params.controlPolicy;
P_YgXn1ZK = controlPolicy.P_YgXn1ZK;

x_num = controller_Params.x_num;
p_pu = controller_Params.p_pu;
batteryParams = controller_Params.batteryParams;
e_pu = batteryParams.e_pu;

edges = [(0:x_num-1)*p_pu inf];
x_k_idxs = discretize(appliance_consumption_original(:,evaluation_interval),edges);
numDays = size(appliance_consumption_original,1);
k_num = controller_Params.k_num;
y_num = controller_Params.y_num;
h_num = controller_Params.h_num;
belief_space = controller_Params.belief_space;
z_num = controller_Params.z_num;
P_XgH = controller_Params.P_XgH;
P_Hp1gH = controller_Params.P_Hp1gH;
P_H_init = controller_Params.P_H_init;
hash_coeffs = controller_Params.hash_coeffs;
belief_space_hash = controller_Params.belief_space_hash;
belief_count = controller_Params.belief_count;
z_max = (z_num-1)*e_pu;
x_offset = controller_Params.x_offset;
y_offset = controller_Params.y_offset;
z_offset = controller_Params.z_offset;
cost = (ones(h_num) - eye(h_num));

y_k_opt_idxs = zeros(numDays,k_num);
y_k_obs_idxs = zeros(numDays,k_num);
z_k_idxs = zeros(numDays,k_num);
socs = zeros(numDays,k_num);
appliance_consumption_pu = zeros(numDays,k_num);
d_ks_obs_pu = zeros(numDays,k_num);

totalEnergyLoss = 0;
ambr = 0;
ambr_adversary = 0;

for dayIdx = 1:numDays
    soc_kn1 = init_soc;
    z_kn1_idx = z_offset+ round(soc_kn1*z_max/e_pu);
    x_kn1 = x_offset;
    belief_kn1 = P_H_init';
    belief_norm = sum(belief_kn1);
    if belief_norm > 0
        belief_kn1 = belief_kn1/belief_norm;
        belief_kn1_hash = floor(sum(hash_coeffs.*belief_kn1));
        belief_kn1_index = find(belief_space_hash>belief_kn1_hash,1)-1;
        if(isempty(belief_kn1_index))
            belief_kn1_index = belief_count;
        end
    else
        belief_kn1_index = (belief_count+1)/2;
    end
    
    belief_kn1_adversary = P_H_init';
    belief_norm = sum(belief_kn1_adversary);
    if belief_norm > 0
        belief_kn1_adversary = belief_kn1_adversary/belief_norm;
        belief_kn1_hash = floor(sum(hash_coeffs.*belief_kn1_adversary));
        belief_kn1_index_adversary = find(belief_space_hash>belief_kn1_hash,1)-1;
        if(isempty(belief_kn1_index_adversary))
            belief_kn1_index_adversary = belief_count;
        end
    else
        belief_kn1_index_adversary = (belief_count+1)/2;
    end    
    
    for k=1:k_num
        y_k_opt_distribution = P_YgXn1ZK(belief_kn1_index,:,x_kn1,z_kn1_idx,k);
        [y_k_opt_idxs(dayIdx,k)] = round(sum((1:y_num).*y_k_opt_distribution));
        [socs(dayIdx,k),y_k_obs_idxs(dayIdx,k)] = simulatBattery(y_k_opt_idxs(dayIdx,k),x_k_idxs(dayIdx,k),soc_kn1,controller_Params);
        appliance_consumption_pu(dayIdx,k) = x_k_idxs(dayIdx,k)-1;
        y_ks_obs_pu = y_k_obs_idxs(dayIdx,k)- y_offset;
        z_k_idxs(dayIdx,k) = z_offset + round(socs(dayIdx,k)*z_max/e_pu);
        d_ks_obs_pu(dayIdx,k) = y_ks_obs_pu - appliance_consumption_pu(dayIdx,k);
        totalEnergyLoss = totalEnergyLoss + batteryLossEstimator(soc_kn1,d_ks_obs_pu(dayIdx,k)*p_pu,batteryParams);
        
        temp = zeros(y_num,1);
        for y_k = 1:y_num
            r_k_y_hat = zeros(h_num,1);
            for h_k_hat = 1:h_num
                for h_k=1:h_num
                    for x_kn1=1:x_num
                        for h_kn1=1:h_num
                            r_k_y_hat(h_k_hat) = r_k_y_hat(h_k_hat) + cost(h_k,h_k_hat)...
                                *P_YgXn1ZK(belief_kn1_index,y_k,x_kn1,z_kn1_idx,k)*P_XgH(x_kn1,h_kn1)*P_Hp1gH(h_k,h_kn1)...
                                *belief_kn1(h_kn1);
                        end
                    end
                end
            end
            temp(y_k) = min(r_k_y_hat);
            ambr = ambr + min(r_k_y_hat);
        end
                
        temp = zeros(y_num,1);
        for y_k = 1:y_num
            r_k_y_hat = zeros(h_num,1);
            for h_k_hat = 1:h_num
                for h_k=1:h_num
                    for x_kn1=1:x_num
                        for h_kn1=1:h_num
                            r_k_y_hat(h_k_hat) = r_k_y_hat(h_k_hat) + cost(h_k,h_k_hat)...
                                *P_YgXn1ZK(belief_kn1_index_adversary,y_k,x_kn1,z_kn1_idx,k)*P_XgH(x_kn1,h_kn1)*P_Hp1gH(h_k,h_kn1)...
                                *belief_kn1_adversary(h_kn1);
                        end
                    end
                end
            end
            temp(y_k) = min(r_k_y_hat);
            ambr_adversary = ambr_adversary + min(r_k_y_hat);
        end
        
        belief_k = zeros(h_num,1);
        for h_k=1:h_num
            belief_k(h_k) = P_XgH(x_k_idxs(dayIdx,k),h_k)*((P_Hp1gH(h_k,:)*belief_kn1));
        end
        belief_norm = sum(belief_k);
        if belief_norm > 0
            belief_k = belief_k/belief_norm;
            belief_k_hash = floor(sum(hash_coeffs.*belief_k));
            belief_k_index = find(belief_space_hash>belief_k_hash,1)-1;
            if(isempty(belief_k_index))
                belief_k_index = belief_count;
            end
        else
            belief_k_index = (belief_count+1)/2;
        end
        belief_k =  belief_space(:,belief_k_index);
        
        belief_k_adversary = zeros(h_num,1);
        for h_k=1:h_num
            belief_k_adversary(h_k) = P_XgH(min(y_k_obs_idxs(dayIdx,k),x_num),h_k)*((P_Hp1gH(h_k,:)*belief_kn1_adversary));
        end
        belief_norm = sum(belief_k_adversary);
        if belief_norm > 0
            belief_k_adversary = belief_k_adversary/belief_norm;
            belief_k_hash = floor(sum(hash_coeffs.*belief_k_adversary));
            belief_k_index_adversary = find(belief_space_hash>belief_k_hash,1)-1;
            if(isempty(belief_k_index_adversary))
                belief_k_index_adversary = belief_count;
            end
        else
            belief_k_index_adversary = (belief_count+1)/2;
        end
        belief_k_adversary =  belief_space(:,belief_k_index_adversary);
        
        belief_kn1 = belief_k;
        belief_kn1_index = belief_k_index;        
        belief_kn1_adversary = belief_k_adversary;
        belief_kn1_index_adversary = belief_k_index_adversary;        
        x_kn1 = x_k_idxs(dayIdx,k);
        soc_kn1 = socs(dayIdx,k);
        z_kn1_idx = z_k_idxs(dayIdx,k);
    end
end

battery_consumption = d_ks_obs_pu*p_pu;
battery_consumption_whole_day = zeros(size(sm_consumption_original));
battery_consumption_whole_day(evaluation_interval) = battery_consumption;
sm_consumption_modified = sm_consumption_original + battery_consumption_whole_day;

simulatedControllerData = struct;
simulatedControllerData.battery_consumption = battery_consumption;
simulatedControllerData.sm_consumption_original = sm_consumption_original;
simulatedControllerData.sm_consumption_modified = sm_consumption_modified;
simulatedControllerData.appliance_consumption_pu = appliance_consumption_pu;
simulatedControllerData.socs = socs;
simulatedControllerData.battery_consumption_whole_day = battery_consumption_whole_day;
simulatedControllerData.totalEnergyLoss = totalEnergyLoss;
simulatedControllerData.ambr = ambr;
simulatedControllerData.ambr_adversary = ambr_adversary;
end