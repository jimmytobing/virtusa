/**
 * @description Provides grant application submission and active support options through Flows.
 */
public without sharing class GrantApplicationController {
  /**
   * @description Submits the applicant's Contact data through the Auto_submitApplication Flow.
   * @param request Contact data to submit for the grant application.
   * @return The Contact ID returned by the Flow, or null if no Contact is returned.
   */
  @AuraEnabled
  public static Id submitApplication(Contact request) {
    System.debug('===== CONTROLLER =====');
    System.debug(JSON.serializePretty(request));
    Flow.Interview.Auto_submitApplication interview = new Flow.Interview.Auto_submitApplication(
      new Map<String, Object>{ 'varR_Contact' => request }
    );
    interview.start();

    Contact savedContact = (Contact) interview.getVariableValue('varR_Contact');
    return (savedContact == null) ? null : savedContact.Id;
  }

  /**
   * @description Retrieves active support options through the Auto_getActiveSupportOptions Flow.
   * @return Support options returned by the Flow, or an empty list if its output is null.
   */
  @AuraEnabled(cacheable=true)
  public static List<Support_Option__c> getActiveSupportOptions() {
    Flow.Interview.Auto_getActiveSupportOptions interview = new Flow.Interview.Auto_getActiveSupportOptions(
      new Map<String, Object>()
    );
    interview.start();

    List<Support_Option__c> supportOptions = (List<Support_Option__c>) interview.getVariableValue(
      'colR_SupportOption'
    );
    return (supportOptions == null)
      ? new List<Support_Option__c>()
      : supportOptions;
  }
}
