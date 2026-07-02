public with sharing class ContactTriggerHandler {
  private static final Pattern SINGAPORE_PHONE_PATTERN = Pattern.compile(
    '^65 [0-9]{4} [0-9]{4}$'
  );
  private static final Pattern POSTAL_CODE_PATTERN = Pattern.compile(
    '^[0-9]{6}$'
  );

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

      if (
        !String.isBlank(record.Phone) &&
        !SINGAPORE_PHONE_PATTERN.matcher(record.Phone).matches()
      ) {
        record.Phone.addError(
          GrantExceptionService.getMessage(
            GrantExceptionService.PHONE_INVALID,
            'Phone must use Singapore format 65 6812 3456.'
          )
        );
      }

      if (
        !String.isBlank(record.MailingPostalCode) &&
        !POSTAL_CODE_PATTERN.matcher(record.MailingPostalCode).matches()
      ) {
        record.MailingPostalCode.addError(
          GrantExceptionService.getMessage(
            GrantExceptionService.POSTAL_CODE_INVALID,
            'Mailing Postal Code must be a 6 digit number.'
          )
        );
      }

      if (record.Monthly_Income__c == null) {
        record.addError(
          GrantExceptionService.getMessage(
            GrantExceptionService.MONTHLY_INCOME_REQUIRED,
            'Monthly Income is required when Support Option is provided.'
          )
        );
      }
    }
  }
}
