public without sharing class GrantApplicationController {
  @AuraEnabled
  public static Id submitApplication(Contact request) {
    System.debug('===== CONTROLLER =====');
    System.debug(JSON.serializePretty(request));
    Flow.Interview.Auto_submitApplication interview = new Flow.Interview.Auto_submitApplication(
      new Map<String, Object>{ 'varR_Contact' => request }
    );
    interview.start();

    Contact savedContact = (Contact) interview.getVariableValue('varR_Contact');
    return savedContact == null ? null : savedContact.Id;
  }

  @AuraEnabled(cacheable=true)
  public static List<Support_Option__c> getActiveSupportOptions() {
    Flow.Interview.Auto_getActiveSupportOptions interview = new Flow.Interview.Auto_getActiveSupportOptions(
      new Map<String, Object>()
    );
    interview.start();

    List<Support_Option__c> supportOptions = (List<Support_Option__c>) interview.getVariableValue(
      'colR_SupportOption'
    );
    return supportOptions == null
      ? new List<Support_Option__c>()
      : supportOptions;
  }
}
