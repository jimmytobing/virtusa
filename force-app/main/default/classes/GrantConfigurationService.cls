public with sharing class GrantConfigurationService {

    public static Grant_Configuration__mdt getConfiguration(
        String grantType
    ){

        Grant_Configuration__mdt config =
            GrantConfigurationRepository.getByGrantType(
                grantType
            );

        if(config == null){

            throw new GrantException(
                'Grant Configuration not found.'
            );

        }

        return config;

    }

    public static List<String> getActiveGrantTypes() {

        List<String> grantTypes = new List<String>();
        Set<String> addedGrantTypes = new Set<String>();

        for (
            Grant_Configuration__mdt config :
            GrantConfigurationRepository.getActiveConfigurations()
        ) {

            if (
                String.isBlank(config.Grant_Type__c) ||
                addedGrantTypes.contains(config.Grant_Type__c)
            ) {
                continue;
            }

            grantTypes.add(config.Grant_Type__c);
            addedGrantTypes.add(config.Grant_Type__c);
        }

        return grantTypes;
    }

}
