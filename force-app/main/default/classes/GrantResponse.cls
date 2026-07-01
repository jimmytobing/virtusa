public with sharing class GrantResponse {

    @AuraEnabled
    public Boolean success;

    @AuraEnabled
    public String message;

    @AuraEnabled
    public Id recordId;

    @AuraEnabled
    public Object data;

}