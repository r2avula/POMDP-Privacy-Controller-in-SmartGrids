function result = bayesianOptimizerMinConObj(P_YgXn1,objParams)
belief_kn1_idx = objParams.belief_kn1_idx;
z_kn1 = objParams.z_kn1;
j_kp1 = objParams.j_kp1;
controller_Params = objParams.controller_Params;
y_num = controller_Params.y_num;
x_num = controller_Params.x_num;
z_num = controller_Params.z_num;
h_num = controller_Params.h_num;
P_XgH = controller_Params.P_XgH;
x_offset = controller_Params.x_offset;
y_offset = controller_Params.y_offset;
z_offset = controller_Params.z_offset;
P_Hp1gH = controller_Params.P_Hp1gH;
belief_space = controller_Params.belief_space;
cost = ones(h_num) - eye(h_num); % for probability of error
hash_coeffs = controller_Params.hash_coeffs;
belief_space_hash = controller_Params.belief_space_hash;
belief_count = controller_Params.belief_count;
batteryParams = controller_Params.batteryParams;
e_pu = batteryParams.e_pu;
p_pu = batteryParams.p_pu;
belief_kn1 = belief_space(:,belief_kn1_idx);
r_k = 0;
for y_k = 1:y_num
    r_k_y_hat = zeros(h_num,1);
    for h_k_hat = 1:h_num
        for h_k=1:h_num
            for x_kn1=1:x_num
                for h_kn1=1:h_num
                    r_k_y_hat(h_k_hat) = r_k_y_hat(h_k_hat) + cost(h_k,h_k_hat)...
                        *P_YgXn1(y_k,x_kn1)*P_XgH(x_kn1,h_kn1)*P_Hp1gH(h_k,h_kn1)...
                        *belief_kn1(h_kn1);
                end
            end
        end
    end
    r_k = r_k + min(r_k_y_hat);
end
exp_j_kp1 = 0;
for x_k = 1:x_num    
    belief_k = zeros(h_num,1);
    for h_k=1:h_num
        belief_k(h_k) = P_XgH(x_k,h_k)*((P_Hp1gH(h_k,:)*belief_kn1));
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
    for y_k=1:y_num        
        d_k = (y_k-y_offset)-(x_k-x_offset);
        soc_k = batteryStateEstimator((z_kn1-z_offset)*e_pu,d_k*p_pu,batteryParams)/((z_num-z_offset)*e_pu);
        possible = 0;
        if(soc_k>1)
            if(z_kn1 ~= z_num)
                temp = batteryStateEstimator((z_kn1-z_offset)*e_pu,(d_k-1)*p_pu,batteryParams)/((z_num-z_offset)*e_pu);
                if(temp < 1)
                    possible = 1;
                    soc_k = 1;
                end
            end
        elseif (soc_k<0)
            if(z_kn1 ~= 1)
                temp = batteryStateEstimator((z_kn1-1)*e_pu,(d_k+1)*p_pu,batteryParams)/((z_num-1)*e_pu);
                if(temp > 0)
                    possible = 1;
                    soc_k = 0;
                end
            end
        else
            possible = 1;
        end
        if(~possible)
            continue
        end
        z_k = z_offset+round(soc_k*(z_num-z_offset));
        for h_k=1:h_num
            for x_kn1=1:x_num                
                for h_kn1=1:h_num
                    exp_j_kp1 = exp_j_kp1 + j_kp1(belief_k_index,z_k)*P_XgH(x_k,h_k)...
                        *P_Hp1gH(h_k,h_kn1)*P_YgXn1(y_k,x_kn1)...
                        *P_XgH(x_kn1,h_kn1)*belief_kn1(h_kn1);
                end
            end
        end
    end
end
result = -(r_k+exp_j_kp1); % -ve sign because of max-to-min conversion
end