trigger GrantDisbursementTrigger on Grant_Disbursement__c(
  after insert,
  after update,
  after delete,
  after undelete
) {
  Set<Id> applicationIds = new Set<Id>();

  if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
    for (Grant_Disbursement__c disbursement : Trigger.new) {
      if (disbursement.Grant_Applicantion__c != null) {
        applicationIds.add(disbursement.Grant_Applicantion__c);
      }
    }
  }

  if (Trigger.isUpdate || Trigger.isDelete) {
    for (Grant_Disbursement__c disbursement : Trigger.old) {
      if (disbursement.Grant_Applicantion__c != null) {
        applicationIds.add(disbursement.Grant_Applicantion__c);
      }
    }
  }

  GrantDisbursementService.clearCompletedApplicationReferences(applicationIds);
}
