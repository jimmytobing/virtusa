public without sharing class GrantApplicationRepository {
  public static Id save(Grant_Application__c application) {
    if (application.Id == null) {
      insert application;
    } else {
      update application;
    }

    return application.Id;
  }

  public static Grant_Application__c getById(Id applicationId) {
    List<Grant_Application__c> apps = [
      SELECT
        Id,
        Applicant__c,
        Grant_Type__c,
        Requested_Amount__c,
        Approved_Amount__c,
        Status__c,
        Eligibility_Score__c
      FROM Grant_Application__c
      WHERE Id = :applicationId
      LIMIT 1
    ];

    return apps.isEmpty() ? null : apps[0];
  }
}
