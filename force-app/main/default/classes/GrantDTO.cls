public with sharing class GrantDTO {

    @AuraEnabled
    public Id applicationId { get; set; }

    @AuraEnabled
    public Id applicantId { get; set; }

    @AuraEnabled
    public String grantType { get; set; }

    @AuraEnabled
    public Decimal requestedAmount { get; set; }

    @AuraEnabled
    public String reason { get; set; }

    @AuraEnabled
    public String status { get; set; }

}