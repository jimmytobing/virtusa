public with sharing class GrantApplicationController {

    @AuraEnabled
    public static Id submitApplication(GrantDTO request) {

        System.debug('===== CONTROLLER =====');
        System.debug(JSON.serializePretty(request));

        return GrantApplicationService.submitApplication(request);
    }

}