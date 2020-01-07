function [plug] = getPlugNr(appliance, house, dataset)

    % returns the plug nr of a specified (appliance, house, dataset)-triple

    appliance_house_matrix = getApplianceHouseMatrix(dataset);   
    plug = num2str(appliance_house_matrix(appliance, house), '%02d');

end

