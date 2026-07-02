public with sharing class ContactTriggerHandler {

    public void beforeInsert(List<Contact> records) {
        validateGrantFields(records);
    }

    public void beforeUpdate(List<Contact> records) {
        validateGrantFields(records);
    }

    public void afterInsert(List<Contact> records) {
        ContactMatchingService.mergeDuplicatePhoneContacts(records);
    }

    private static void validateGrantFields(List<Contact> records) {
        for (Contact record : records) {
            if (String.isBlank(record.Support_Option__c)) {
                continue;
            }

            if (record.Monthly_Income__c == null) {
                record.addError(
                    'Monthly Income is required when Support Option is provided.'
                );
            }

        }
    }
}
