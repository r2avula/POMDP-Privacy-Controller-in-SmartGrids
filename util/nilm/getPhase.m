function [phase] = getPhase(household, applianceID, dataset)

    % returns the phase of the specified (house, appliance)-pair

    phase_matrix = getPhaseMatrix(dataset);       
    phase = phase_matrix(applianceID, household);

end

