public with sharing class GrantDTO {
  @AuraEnabled
  public Id applicationId { get; set; }

  @AuraEnabled
  public Id applicantId { get; set; }

  @AuraEnabled
  public String firstName { get; set; }

  @AuraEnabled
  public String lastName { get; set; }

  @AuraEnabled
  public String phone { get; set; }

  @AuraEnabled
  public String email { get; set; }

  @AuraEnabled
  public String mailingPostalCode { get; set; }

  @AuraEnabled
  public Decimal monthlyIncome { get; set; }

  @AuraEnabled
  public String supportOption { get; set; }

  @AuraEnabled
  public String grantType { get; set; }

  @AuraEnabled
  public Decimal requestedAmount { get; set; }

  @AuraEnabled
  public String reason { get; set; }

  @AuraEnabled
  public String status { get; set; }
}
