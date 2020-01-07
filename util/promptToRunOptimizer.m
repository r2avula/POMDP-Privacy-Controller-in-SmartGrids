function [temp] = promptToRunOptimizer(controller_Params)
promptMessage = sprintf('Control policy is missing. Run optimizer now? (y/n): ');
str = input(promptMessage,'s');
if(str(1) == 'y')
    [P_YgXn1ZK,value_function, exitflag, vale_function_resets] = bayesianOptimizerMinCon(controller_Params);    
    saved = 0;
    temp = 1;
    while(~saved)
        filename = strcat('cache/controlPolicy_',num2str(temp),'.mat');
        if exist(filename, 'file')
            temp=temp+1;
        else
            save(filename, 'P_YgXn1ZK','value_function', 'exitflag', 'controller_Params','vale_function_resets');
            saved=1;
        end
    end
    fprintf('Optimization complete. Policy saved in ''%s''.\n',filename);   
else
    error('Control policy is missing. Run optimizer first.')
end
end