function energyLoss = batteryLossEstimator(soc_curr,d_k,batteryParams)
slotIntervalInHours = batteryParams.slotIntervalInHours;
e_pu = batteryParams.e_pu;
z_num = batteryParams.z_num;
z_max = (z_num-1)*e_pu;
batteryNominalVoltage = batteryParams.batteryNominalVoltage;
alphah = batteryParams.alphah;
betah = batteryParams.betah;
converterEfficiency = batteryParams.converterEfficiency;
batteryInternalResistance = batteryParams.batteryInternalResistance;
energyLoss = (1-alphah)*soc_curr*z_max + d_k*slotIntervalInHours - ...
    betah*(sqrt(max((batteryNominalVoltage*batteryNominalVoltage)+4*batteryInternalResistance*d_k*converterEfficiency^(sign(d_k)),0))-batteryNominalVoltage);
end