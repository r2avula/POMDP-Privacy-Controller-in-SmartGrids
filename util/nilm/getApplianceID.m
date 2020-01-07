function [applianceID] = getApplianceID(applianceName)

    % returns the ID of an appliance

    cellWithAllApplianceNames = getCellWithAllApplianceNames();
    applianceID = find(strcmpi(cellWithAllApplianceNames, applianceName));

end

