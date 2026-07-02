public with sharing class GrantExceptionService {
  public static final String REQUEST_NULL = 'REQUEST_NULL';
  public static final String APPLICANT_FIRST_NAME_REQUIRED = 'APPLICANT_FIRST_NAME_REQUIRED';
  public static final String APPLICANT_LAST_NAME_REQUIRED = 'APPLICANT_LAST_NAME_REQUIRED';
  public static final String PHONE_INVALID = 'PHONE_INVALID';
  public static final String EMAIL_INVALID = 'EMAIL_INVALID';
  public static final String POSTAL_CODE_INVALID = 'POSTAL_CODE_INVALID';
  public static final String MONTHLY_INCOME_INVALID = 'MONTHLY_INCOME_INVALID';
  public static final String MONTHLY_INCOME_REQUIRED = 'MONTHLY_INCOME_REQUIRED';
  public static final String SUPPORT_OPTION_REQUIRED = 'SUPPORT_OPTION_REQUIRED';
  public static final String SUPPORT_OPTION_UNAVAILABLE = 'SUPPORT_OPTION_UNAVAILABLE';
  public static final String GRANT_CONFIGURATION_NOT_FOUND = 'GRANT_CONFIGURATION_NOT_FOUND';
  public static final String DISBURSEMENT_OPTION_TOTAL_TOO_LOW = 'DISBURSEMENT_OPTION_TOTAL_TOO_LOW';
  public static final String DISBURSEMENT_OPTION_NO_MONTHS = 'DISBURSEMENT_OPTION_NO_MONTHS';
  public static final String REST_CALLOUT_FAILED = 'REST_CALLOUT_FAILED';
  public static final String UNEXPECTED_ERROR = 'UNEXPECTED_ERROR';
  public static final String UNEXPECTED_ERROR_NULL = 'UNEXPECTED_ERROR_NULL';

  public static String getMessage(String code, String defaultMessage) {
    if (String.isBlank(code)) {
      return defaultMessage;
    }

    Grant_Error_Message__mdt errorMessage = Grant_Error_Message__mdt.getInstance(
      code
    );

    if (
      errorMessage != null &&
      errorMessage.Active__c == true &&
      !String.isBlank(errorMessage.Message__c)
    ) {
      return errorMessage.Message__c;
    }

    return defaultMessage;
  }

  public static String formatMessage(
    String code,
    String defaultMessage,
    List<String> values
  ) {
    String message = getMessage(code, defaultMessage);

    if (values == null) {
      return message;
    }

    for (Integer index = 0; index < values.size(); index++) {
      message = message.replace(
        '{' + String.valueOf(index) + '}',
        values[index] == null ? '' : values[index]
      );
    }

    return message;
  }

  @AuraEnabled(cacheable=true)
  public static Map<String, String> getClientMessages() {
    Map<String, String> messagesByCode = new Map<String, String>();

    messagesByCode.put(
      PHONE_INVALID,
      getMessage(PHONE_INVALID, 'Phone must use Singapore format 65 6812 3456.')
    );
    messagesByCode.put(
      POSTAL_CODE_INVALID,
      getMessage(
        POSTAL_CODE_INVALID,
        'Mailing Postal Code must be a 6 digit number.'
      )
    );
    messagesByCode.put(
      UNEXPECTED_ERROR,
      getMessage(UNEXPECTED_ERROR, 'Unexpected error.')
    );
    messagesByCode.put(
      UNEXPECTED_ERROR_NULL,
      getMessage(UNEXPECTED_ERROR_NULL, 'Unexpected error(null).')
    );

    return messagesByCode;
  }
}
