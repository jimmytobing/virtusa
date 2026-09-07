// Seed message codes from GrantExceptionService. Safe to rerun: match existing records by Name.
// Run: sf apex run --target-org hdbsf --file scripts/apex/seedGrantMessages.apex
Map<String, String> messagesByCode = new Map<String, String>{
    'REQUEST_NULL' => 'Request is required.',
    'APPLICANT_FIRST_NAME_REQUIRED' => 'Applicant first name is required.',
    'APPLICANT_LAST_NAME_REQUIRED' => 'Applicant last name is required.',
    'PHONE_INVALID' => 'Phone must use Singapore format 65 6812 3456.',
    'EMAIL_INVALID' => 'Enter a valid email address.',
    'POSTAL_CODE_INVALID' => 'Mailing Postal Code must be a 6 digit number.',
    'MONTHLY_INCOME_INVALID' => 'Enter a valid monthly income.',
    'MONTHLY_INCOME_REQUIRED' => 'Monthly income is required.',
    'SUPPORT_OPTION_REQUIRED' => 'Select a support option.',
    'SUPPORT_OPTION_UNAVAILABLE' => 'The selected support option is unavailable.',
    'GRANT_CONFIGURATION_NOT_FOUND' => 'Grant configuration was not found.',
    'DISBURSEMENT_OPTION_TOTAL_TOO_LOW' => 'The disbursement option total is too low.',
    'DISBURSEMENT_OPTION_NO_MONTHS' => 'The disbursement option has no months configured.',
    'REST_CALLOUT_FAILED' => 'The request to the external service failed.',
    'UNEXPECTED_ERROR' => 'Unexpected error.',
    'UNEXPECTED_ERROR_NULL' => 'Unexpected error(null).'
};

List<Grant_Message__c> messagesToSave = new List<Grant_Message__c>();
Set<String> existingCodes = new Set<String>();
for (Grant_Message__c message : [
    SELECT Id, Name, Message_Text__c
    FROM Grant_Message__c
    WHERE Name IN :messagesByCode.keySet()
]) {
    existingCodes.add(message.Name);
    message.Message_Text__c = messagesByCode.get(message.Name);
    messagesToSave.add(message);
}
for (String code : messagesByCode.keySet()) {
    if (!existingCodes.contains(code)) {
        messagesToSave.add(new Grant_Message__c(
            Name = code,
            Message_Text__c = messagesByCode.get(code)
        ));
    }
}
upsert messagesToSave;
System.debug(LoggingLevel.INFO, 'Grant messages saved: ' + messagesToSave.size());
