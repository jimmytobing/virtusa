public with sharing class GrantApplicationController {
  @AuraEnabled
  public static Id submitApplication(Contact request) {
    System.debug('===== CONTROLLER =====');
    System.debug(JSON.serializePretty(request));
    return null;
  }

  @AuraEnabled(cacheable=true)
  public static List<Support_Option__c> getActiveSupportOptions() {
    return null;
  }
}
