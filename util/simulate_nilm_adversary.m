function [recognizedEvents] = simulate_nilm_adversary(adversary_Params,evaluationDates,batteryConsumption)
recognizedEvents = [];

[events, times] = get_events_of_single_phase_applianceNew(adversary_Params,evaluationDates,batteryConsumption);

r = adversary_Params.r;
osc = adversary_Params.osc;
signature_database = adversary_Params.signature_database;
appliancePhase = adversary_Params.appliancePhase;
appliance_name = adversary_Params.appliance_name;
applianceID = adversary_Params.applianceID;
signatures = signature_database.signatures;
numOfSignatures = size(signatures,1);
signatureLength = zeros(numOfSignatures,1);
for j = 1:numOfSignatures
    signatureLength(j,1) = norm(signatures(j,:));
end
signatureLength = signatureLength(signature_database.phases == appliancePhase);
signatures_on_phase = signatures(signature_database.phases == appliancePhase, 1:2);
signatureNames = signature_database.names(signature_database.phases == appliancePhase);

signatures_previous_phases = 0;
if appliancePhase == 2
    signatures_previous_phases = signatures_previous_phases + sum(signature_database.phases < 2);
elseif appliancePhase == 3
    signatures_previous_phases = signatures_previous_phases + sum(signature_database.phases < 3);
end

% assign each event to its best match in the signature database
[signatureIDs, dist] = knnsearch(signatures_on_phase, events(:,1:2));
if ~isempty(signatureIDs)
    dist_threshold = r*signatureLength(signatureIDs,1) + osc*events(:,4);
    matching_valid = dist < dist_threshold;
    matching_ids = find(strcmp(signatureNames, appliance_name));
    matching_valid = matching_valid & ismember(signatureIDs, matching_ids);
    recognizedEvents = [recognizedEvents;...
        times(matching_valid), applianceID*ones(size(signatureIDs(matching_valid))) + signatures_previous_phases, events(matching_valid, 1:3)];
end

end