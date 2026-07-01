public with sharing class GrantEligibilityService {

    public static EligibilityResult evaluate(
        Id applicantId,
        String grantType,
        Decimal requestedAmount
    ){

        Contact applicant =
            ContactRepository.getById(
                applicantId
            );

        Grant_Configuration__mdt config =
            GrantConfigurationService.getConfiguration(
                grantType
            );

        EligibilityResult result =
            new EligibilityResult();

        if(applicant == null){

            result.eligible = false;
            result.message = 'Applicant not found';

            return result;

        }

        Integer age = applicant.Birthdate == null
            ? 0
            : applicant.Birthdate.daysBetween(Date.today()) / 365;

        if(age < config.Minimum_Age__c
        || age > config.Maximum_Age__c){

            result.eligible = false;
            result.message = 'Age criteria not met';

            return result;

        }

        if(applicant.Annual_Income__c >
            config.Income_Threshold__c){

            result.eligible = false;
            result.message = 'Income exceeds threshold';

            return result;

        }

        result.eligible = true;

        result.approvedAmount =
            Math.min(
                requestedAmount,
                config.Maximum_Amount__c
            );

        result.score = 100;

        result.message = 'Eligible';

        return result;

    }

}