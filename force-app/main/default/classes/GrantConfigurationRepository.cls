public with sharing class GrantConfigurationRepository {

    /**
     * Retrieves the active configuration for a grant type.
     */
    public static Grant_Configuration__mdt getByGrantType(String grantType) {

        System.debug('grantType=[' + grantType + ']');

        List<Grant_Configuration__mdt> configs = [
            SELECT
                Grant_Type__c,
                Maximum_Amount__c,
                Income_Threshold__c,
                Minimum_Age__c,
                Maximum_Age__c,
                Priority__c,
                Active__c
            FROM Grant_Configuration__mdt
            WHERE Grant_Type__c = :grantType
            AND Active__c = TRUE
            ORDER BY Priority__c
            LIMIT 1
        ];

        System.debug('>>> configs size = ' + configs.size());
        return configs.isEmpty() ? null : configs[0];
    }
}