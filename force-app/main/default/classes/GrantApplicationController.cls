public with sharing class GrantApplicationController {
  @AuraEnabled
  public static Id submitApplication(GrantDTO request) {
    System.debug('===== CONTROLLER =====');
    System.debug(JSON.serializePretty(request));

    try {
      return GrantApplicationService.submitApplication(request);
    } catch (Exception exceptionRecord) {
      throw new AuraHandledException(exceptionRecord.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<String> getActiveGrantTypes() {
    return GrantConfigurationService.getActiveGrantTypes();
  }

  @AuraEnabled(cacheable=true)
  public static List<GrantSupportOptionDTO> getActiveSupportOptions() {
    return GrantSupportOptionService.getActiveOptions();
  }
}
