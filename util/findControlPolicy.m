function [policyfilename] = findControlPolicy(controller_Params_)
loaded = 0;
file_idx = 1;
policyfilename = strcat('cache/controlPolicy_',num2str(file_idx),'.mat');
if ~(exist(policyfilename, 'file'))
    promptToRunOptimizer(controller_Params_);
else
    file_idx=file_idx+1;
end
snap = 0;
matchCount = 0;
while(~loaded)
    policyfilename = strcat('cache/controlPolicy_',num2str(file_idx),'.mat');
    if exist(policyfilename, 'file')
        file_idx=file_idx+1;
    else
        matched = 0;
        while(~matched)
            if(file_idx < 2)
                file_idx = promptToRunOptimizer(controller_Params_);
                file_idx=file_idx+1;
            end
            file_idx=file_idx-1;
            policyfilename = strcat('cache/controlPolicy_',num2str(file_idx),'.mat');
            load(policyfilename);
            if(isequaln(controller_Params_,controller_Params))
                if(snap == 0)
                    snap = file_idx;
                end
                matched = 1;
                matchCount = matchCount+1;
            end
        end
        policyfilename = strcat('cache/controlPolicy_',num2str(snap),'.mat');        
        loaded=1;
        fprintf('Cache  found in %s\n',policyfilename);
    end
end
end