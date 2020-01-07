function z_next_vec=batteryStateEstimator(z_curr,d_vec,batteryParams)
converterEfficiency = batteryParams.converterEfficiency;
batteryNominalVoltage = batteryParams.batteryNominalVoltage;
alphah = batteryParams.alphah;
betah = batteryParams.betah;
batteryInternalResistance = batteryParams.batteryInternalResistance;
pos_d_logic = d_vec>0;
pos_d = d_vec(pos_d_logic);
neg_d_logic = d_vec<=0;
neg_d = d_vec(neg_d_logic);
z_next_vec = z_curr*(ones(size(d_vec)));
if(sum(pos_d_logic)>0)
    z_next_vec(pos_d_logic) = alphah*z_curr + betah*(sqrt(max((batteryNominalVoltage*batteryNominalVoltage)+4*batteryInternalResistance*pos_d*converterEfficiency,0))-batteryNominalVoltage);
end
if(sum(neg_d_logic)>0)
    z_next_vec(neg_d_logic) = alphah*z_curr + betah*(sqrt(max((batteryNominalVoltage*batteryNominalVoltage)+4*batteryInternalResistance*neg_d/converterEfficiency,0))-batteryNominalVoltage);
end
end