% Returns a matrix that specifies the plug no. of each (appliance, house) pair
function [appliance_house_matrix] = getApplianceHouseMatrix(dataset)

    if strcmpi(dataset, 'eco')
         appliance_house_matrix = [ %(appliance,house)
             1 4  5 1 5 6;        % fridge
             7 6  2 5 0 0;        % freezer
             0 0  0 8 4 0;        % microwave
             0 2  0 0 0 0;        % dishwasher
             0 0  7 7 6 5;        % entertainment
             4 7  6 0 8 8;        % water kettle
             0 10 0 0 0 0;        % cooker
             3 0  3 2 2 4;        % coffee machine  
             5 0  0 0 0 0;        % washing machine
             2 0  0 0 0 0;        % dryer
             0 8  0 3 0 1;        % lamp   
             6 0  4 0 7 0;        % pc 
             0 9  0 0 0 2;        % laptop
             0 11 0 0 0 0;        % tv
             0 12 0 4 0 0;        % stereo
             0 1  1 6 1 0;        % tablet
             0 0  0 0 0 3;        % router
             0 0  0 0 3 0];       % illuminated fountain

    elseif strcmpi(dataset, 'redd')
        appliance_house_matrix = [ % (appliance,house)
             1 4  0 1 5 6;        % fridge
             7 6  0 5 0 7;        % freezer
             0 0  0 8 4 0;        % microwave
             0 0  0 0 0 0;        % dishwasher
             0 0  0 7 0 5;        % entertainment
             4 0  0 0 3 8;        % water kettle
             0 0  0 0 0 0;        % cooker
             3 0  0 2 2 4;        % coffee machine  
             5 0  0 0 0 0;        % washing machine
             2 0  0 0 0 0;        % dryer
             0 0  0 3 0 6;        % lamp   
             0 0  0 0 7 0;        % pc 
             0 0  0 0 0 0;        % laptops
             0 0  0 0 0 0;        % entertainment_tv
             0 0  0 0 0 0];       % entertainment_rest
    else
        error('dataset not available');
    end
end

