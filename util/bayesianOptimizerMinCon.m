function [P_YgXn1ZK,value_function,exitflag,vale_function_resets] = bayesianOptimizerMinCon(controller_Params)
y_num = controller_Params.y_num;
x_num = controller_Params.x_num;
z_num = controller_Params.z_num;
k_num = controller_Params.k_num;
belief_count = controller_Params.belief_count;
P_YgXn1ZK = zeros(belief_count,y_num,x_num,z_num,k_num);
exitflag = -5*ones(belief_count,z_num,k_num);
value_function = zeros(belief_count,z_num,k_num+1);
fprintf('Running optimizer for each time step\n'); 
optOptions = optimoptions('fmincon','SpecifyConstraintGradient',true,'Display','off','MaxFunctionEvaluations',5000,'MaxIterations',2000);
opt_Aeq = repelem(eye(x_num),1,y_num);
opt_beq = ones(1,x_num);
opt_lb = zeros(y_num,x_num);
opt_ub = ones(y_num,x_num);
value_function(:,:,k_num+1) = 1;
vale_function_resets = 0;
for t = k_num:-1:1
    disp(t);
    j_kp1 = value_function(:,:,t+1);
    sum_value_function = sum(j_kp1(:));
    if(sum_value_function == 0)
        j_kp1 = ones(size(j_kp1));
        vale_function_resets = vale_function_resets + 1;
    end
    parfor belief_kn1_idx=1:belief_count  
        x0 = zeros(y_num,x_num,z_num);
        x0(1,:,:)=1;
        for z_kn1=1:z_num
            objParams = struct;
            objParams.belief_kn1_idx = belief_kn1_idx;
            objParams.z_kn1 = z_kn1;
            objParams.j_kp1 = j_kp1;
            objParams.controller_Params = controller_Params;
            %   note that we are using minmax function
            %   maxmin(f(x)) = -minmax(-f(x))
            %   'bayesianOptimizerMinMaxObj' internally computes -f(x)
            [x,fval,exitflag(belief_kn1_idx,z_kn1,t),~] = fmincon(@(x)bayesianOptimizerMinConObj(x,objParams), x0(:,:,z_kn1), [], [], opt_Aeq,opt_beq, opt_lb, opt_ub, @(x)bayesianOptimizerMinConCon(x,objParams), optOptions);
            P_YgXn1ZK(belief_kn1_idx,:,:,z_kn1,t) = x;
            value_function(belief_kn1_idx,z_kn1,t)=-fval; % min-to-max conversion
            x0(:,:,z_kn1)=x;
        end        
    end
end
end
