public with sharing class GrantApplicationTriggerHandler {

    public void beforeInsert(
        List<Grant_Application__c> records
    ) {

        for (Grant_Application__c app : records) {

            if (app.Current_Stage__c == null) {
                app.Current_Stage__c = 'Submitted';
            }

        }

    }

    public void beforeUpdate(
        List<Grant_Application__c> records,
        Map<Id, Grant_Application__c> oldMap
    ) {

    }

    public void afterInsert(
        List<Grant_Application__c> records
    ) {

    }

    public void afterUpdate(
        List<Grant_Application__c> records,
        Map<Id, Grant_Application__c> oldMap
    ) {

    }

}