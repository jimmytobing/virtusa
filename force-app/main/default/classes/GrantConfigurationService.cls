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

}