public with sharing class EligibilityResult {

    @AuraEnabled
    public Boolean eligible;

    @AuraEnabled
    public Decimal approvedAmount;

    @AuraEnabled
    public Integer score;

    @AuraEnabled
    public String message;

}