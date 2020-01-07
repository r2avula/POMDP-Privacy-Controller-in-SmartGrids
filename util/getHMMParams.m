function [mean,covs,trans,p_init,obs_prob,training_data_state] = getHMMParams(training_data,state_bounds,x_num,p_pu)
bounds_size = length(state_bounds);
num_states = bounds_size + 1;
T = length(training_data);
training_data_state = zeros(1,T);
obs_prob = zeros(x_num,num_states);
p_init = zeros(1,num_states);
trans = zeros(num_states);  %x-prev_state, y-cur_state
mean = zeros(1,num_states);
covs = zeros(1,num_states);
edges = [(0:x_num-1)*p_pu inf];
missingDataCount = 0;

for t=1:T
    if(training_data(t) == -1)
        missingDataCount = missingDataCount+1;
        continue
    end
    if(bounds_size == 1)
        if(training_data(t) < state_bounds(1))
            training_data_state(t) = 1;
            p_init(1) = p_init(1) + 1 ;
        else
            training_data_state(t) = 2;   
            p_init(2) = p_init(2) + 1 ;         
        end
    else
        if(training_data(t) >= state_bounds(bounds_size))
            training_data_state(t) = bounds_size+1;            
            continue
        end
        if(training_data(t) <= state_bounds(1))
            training_data_state(t) = 1;
            p_init(1) = p_init(1) + 1 ;
            continue
        else
            for b = 2: bounds_size
                if(training_data(t) <= state_bounds(b))
                    training_data_state(t) = b;
                    p_init(b) = p_init(b) + 1 ;
                    break;
                end
            end
        end
    end
end

training_data_quant2 = training_data_state(training_data_state ~= 0);
newT = length(training_data_quant2);
if(missingDataCount~= T-newT)
    error('Something is wrong!');
end
prev_state = training_data_quant2(1);
for t = 2:newT
    cur_state = training_data_quant2(t);
    trans(cur_state,prev_state) = trans(cur_state,prev_state) +1;
    prev_state = cur_state;
end

for i=1:num_states
    
    trans(:,i) = trans(:,i)/sum(trans(:,i));
    
    temp1 = training_data(training_data_state == i);
    temp1(temp1 < 0)=0;
    obs_prob(:,i) = histcounts(temp1,edges)'./length(temp1);    
    mean(i) = sum(temp1)/length(temp1);
    temp2 = (temp1 - mean(i)).^2;
    covs(i) = sum(temp2)/length(temp1);  
end

p_init = p_init /newT;
