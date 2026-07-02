public without sharing class GrantApplicationGuestUpdateJob implements Queueable {
  private final Id applicationId;
  private final Id applicantId;
  private final String grantType;
  private final Decimal requestedAmount;
  private final String reason;

  public GrantApplicationGuestUpdateJob(
    Id applicationId,
    Id applicantId,
    String grantType,
    Decimal requestedAmount,
    String reason
  ) {
    this.applicationId = applicationId;
    this.applicantId = applicantId;
    this.grantType = grantType;
    this.requestedAmount = requestedAmount;
    this.reason = reason;
  }

  public void execute(QueueableContext context) {
    if (applicationId == null) {
      return;
    }

    Grant_Application__c application = new Grant_Application__c(
      Id = applicationId,
      Grant_Type__c = grantType,
      Requested_Amount__c = requestedAmount,
      Reason__c = reason,
      Status__c = GrantConstants.STATUS_PENDING,
      Application_Date__c = Date.today(),
      Submitted_Date__c = Datetime.now()
    );

    if (applicantId != null) {
      application.Applicant__c = applicantId;
    }

    update application;

    if (applicantId != null) {
      update new Contact(
        Id = applicantId,
        Grant_Application__c = applicationId
      );
    }

    GrantDisbursementService.recalculateForApplicationIds(
      new Set<Id>{ applicationId }
    );
  }
}
