function [c, ceq,gradc,gradceq] = bayesianOptimizerMinConCon(P_YgXn1,objParams)
z_kn1 = objParams.z_kn1;
controller_Params = objParams.controller_Params;
y_num = controller_Params.y_num;
x_num = controller_Params.x_num;
z_num = controller_Params.z_num;
x_offset = controller_Params.x_offset;
y_offset = controller_Params.y_offset;
z_offset = controller_Params.z_offset;
batteryParams = controller_Params.batteryParams;
e_pu = batteryParams.e_pu;
p_pu = batteryParams.p_pu;
c = [];
ceq = zeros(1,x_num*y_num);
gradceq_t = zeros(x_num*y_num,x_num*y_num);

for y_k=1:y_num
    possible = 1;
    d_ch_min = (y_k-y_offset)-(x_num-x_offset);
    d_disch_min = (y_k-y_offset);
    if(d_ch_min>0)
        soc_k_ch_min = batteryStateEstimator((z_kn1-z_offset)*e_pu,d_ch_min*p_pu,batteryParams)/((z_num-z_offset)*e_pu);
        if(soc_k_ch_min>1)
            possible = 0;
        end
    end
    if(d_disch_min<0)
        soc_k_disch_min = batteryStateEstimator((z_kn1-z_offset)*e_pu,d_disch_min*p_pu,batteryParams)/((z_num-z_offset)*e_pu);
        if(soc_k_disch_min<0)
            possible = 0;
        end
    end
    if(~possible)        
        for x_kn1=1:x_num
            ceq(((y_k-1)*x_num)+x_kn1) = P_YgXn1(y_k,x_kn1);
            gradceq_t(((y_k-1)*x_num)+x_kn1,((y_k-1)*x_num)+x_kn1) = 1;
        end
    end
end
if nargout > 2
    gradc = [];
    gradceq = gradceq_t;
end
end