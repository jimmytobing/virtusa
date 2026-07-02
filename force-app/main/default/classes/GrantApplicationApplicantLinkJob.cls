public without sharing class GrantApplicationApplicantLinkJob implements Queueable {
  private final Id applicationId;
  private final Id applicantId;

  public GrantApplicationApplicantLinkJob(Id applicationId, Id applicantId) {
    this.applicationId = applicationId;
    this.applicantId = applicantId;
  }

  public void execute(QueueableContext context) {
    if (applicationId == null || applicantId == null) {
      return;
    }

    update new Grant_Application__c(
      Id = applicationId,
      Applicant__c = applicantId
    );

    update new Contact(Id = applicantId, Grant_Application__c = applicationId);

    GrantDisbursementService.recalculateForApplicationIds(
      new Set<Id>{ applicationId }
    );
  }
}
