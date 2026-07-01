public with sharing class GrantSupportOptionService {

    public static List<GrantSupportOptionDTO> getActiveOptions() {
        List<GrantSupportOptionDTO> options =
            new List<GrantSupportOptionDTO>();

        for (Grant_Support_Option__mdt option : [
            SELECT
                DeveloperName,
                MasterLabel,
                Monthly_Amount__c,
                Duration_Months__c,
                Active__c,
                Sort_Order__c
            FROM Grant_Support_Option__mdt
            WHERE Active__c = TRUE
            ORDER BY Sort_Order__c, MasterLabel
        ]) {
            options.add(new GrantSupportOptionDTO(option));
        }

        return options;
    }

    public static Grant_Support_Option__mdt getActiveOption(
        String developerName
    ) {
        if (String.isBlank(developerName)) {
            throw new GrantException('Support Option is required.');
        }

        List<Grant_Support_Option__mdt> options = [
            SELECT
                DeveloperName,
                MasterLabel,
                Monthly_Amount__c,
                Duration_Months__c,
                Active__c,
                Sort_Order__c
            FROM Grant_Support_Option__mdt
            WHERE DeveloperName = :developerName
            AND Active__c = TRUE
            LIMIT 1
        ];

        if (options.isEmpty()) {
            throw new GrantException('Support Option is not available.');
        }

        return options[0];
    }
}
