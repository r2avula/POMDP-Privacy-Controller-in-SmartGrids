function [soc_out,y_k_idx] = simulatBattery(y_k_opt_idx,x_k_idx,soc_kn1,controller_Params)
d_max_pu = controller_Params.d_ch_max_pu;
d_min_pu = controller_Params.d_disch_max_pu;
p_pu = controller_Params.batteryParams.p_pu;

batteryParams = controller_Params.batteryParams;
x_offset = controller_Params.x_offset;
y_offset = controller_Params.y_offset;
y_k_opt_pu = y_k_opt_idx - y_offset;
x_k_pu = x_k_idx - x_offset;
z_num = controller_Params.z_num;
e_pu = controller_Params.batteryParams.e_pu;
z_max = (z_num-1)*e_pu;

batteryNominalVoltage = batteryParams.batteryNominalVoltage;
alphah = batteryParams.alphah;
betah = batteryParams.betah;
converterEfficiency = batteryParams.converterEfficiency;
batteryInternalResistance = batteryParams.batteryInternalResistance;
%% min power
first_term = ((0-alphah*soc_kn1)*z_max/betah) + batteryNominalVoltage;
d_k_min = ((max(first_term,0)).^2 - (batteryNominalVoltage)^2)*converterEfficiency/(4*batteryInternalResistance);
d_k_min_pu = max(round(d_k_min/p_pu),d_min_pu);

%% max power
first_term = ((1-alphah*soc_kn1)*z_max/betah) + batteryNominalVoltage;
d_k_max = ((first_term).^2 - (batteryNominalVoltage)^2)/(4*converterEfficiency*batteryInternalResistance);
d_k_max_pu = min(round(d_k_max/p_pu),d_max_pu);

%% schedule if requested power is possible
if(y_k_opt_pu < x_k_pu + d_k_min_pu)
    y_k_pu = x_k_pu + d_k_min_pu;
elseif (y_k_opt_pu > x_k_pu + d_k_max_pu)
    y_k_pu = x_k_pu + d_k_max_pu;
else
    y_k_pu = y_k_opt_pu;
end
y_k_idx = y_k_pu + y_offset;

soc_out = min(max(batteryStateEstimator(soc_kn1*z_max,(y_k_pu - x_k_pu)*p_pu,batteryParams)/z_max,0),1);
end

