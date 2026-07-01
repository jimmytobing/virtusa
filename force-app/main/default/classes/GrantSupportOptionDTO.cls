public with sharing class GrantSupportOptionDTO {

    @AuraEnabled
    public String value { get; set; }

    @AuraEnabled
    public String label { get; set; }

    @AuraEnabled
    public Decimal monthlyAmount { get; set; }

    @AuraEnabled
    public Integer durationMonths { get; set; }

    @AuraEnabled
    public Decimal totalAmount { get; set; }

    public GrantSupportOptionDTO(
        Grant_Support_Option__mdt option
    ) {
        value = option.DeveloperName;
        label = option.MasterLabel;
        monthlyAmount = option.Monthly_Amount__c;
        durationMonths = option.Duration_Months__c == null
            ? 0
            : option.Duration_Months__c.intValue();
        totalAmount = monthlyAmount * durationMonths;
    }
}
