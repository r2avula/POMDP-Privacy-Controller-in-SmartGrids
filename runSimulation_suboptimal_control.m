clear;
path_to_data = simStartup();

controller_config_filename = 'pomdp_control_kettle_usage_house_2_1minute.yaml';
controller_config = ReadYaml(controller_config_filename);
controller_config.path_to_data = path_to_data;
availableData_controller = fetchData(controller_config);

trainingDaysCount_controller = controller_config.trainingDaysCount;
trainingData_controller = availableData_controller.appliance_consumption(1:trainingDaysCount_controller,:);
[controller_Params] = initControllerParams(controller_config,trainingData_controller);
controlPolicyFilename = findControlPolicy(controller_Params);
controller_Params.controlPolicy = load(controlPolicyFilename);

evaluationDaysCount = controller_config.evaluationDaysCount;
evaluationDayOffset = controller_config.evaluationDayOffset;
evaluationDateRange = (trainingDaysCount_controller+1+evaluationDayOffset:trainingDaysCount_controller+evaluationDaysCount+evaluationDayOffset);    
evaluationData_appliance = availableData_controller.appliance_consumption(evaluationDateRange,:);
evaluationData_sm = availableData_controller.sm_consumption(evaluationDateRange,:);
evaluationDates = availableData_controller.availableDates(evaluationDateRange,:);

simulatedControllerData_50 = simulate_pomdp_controller(controller_Params,evaluationData_appliance,evaluationData_sm,0.5); % with 50% SOC initialization
simulatedControllerData_100 = simulate_pomdp_controller(controller_Params,evaluationData_appliance,evaluationData_sm,1); % with 100% SOC initialization
plotFigures__suboptimal_control(controller_Params,evaluationDates,simulatedControllerData_50,simulatedControllerData_100);

fprintf('Simulation complete.\n');
