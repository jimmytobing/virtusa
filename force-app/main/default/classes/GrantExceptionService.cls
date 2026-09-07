/**
 * @description Defines grant error codes and provides fallback messages for server and client use.
 */
public with sharing class GrantExceptionService {
  /**
   * @description Error code for a missing request.
   */
  public static final String REQUEST_NULL = 'REQUEST_NULL';
  /**
   * @description Error code for a missing applicant first name.
   */
  public static final String APPLICANT_FIRST_NAME_REQUIRED = 'APPLICANT_FIRST_NAME_REQUIRED';
  /**
   * @description Error code for a missing applicant last name.
   */
  public static final String APPLICANT_LAST_NAME_REQUIRED = 'APPLICANT_LAST_NAME_REQUIRED';
  /**
   * @description Error code for an invalid phone number.
   */
  public static final String PHONE_INVALID = 'PHONE_INVALID';
  /**
   * @description Error code for an invalid email address.
   */
  public static final String EMAIL_INVALID = 'EMAIL_INVALID';
  /**
   * @description Error code for an invalid postal code.
   */
  public static final String POSTAL_CODE_INVALID = 'POSTAL_CODE_INVALID';
  /**
   * @description Error code for an invalid monthly income.
   */
  public static final String MONTHLY_INCOME_INVALID = 'MONTHLY_INCOME_INVALID';
  /**
   * @description Error code for a missing monthly income.
   */
  public static final String MONTHLY_INCOME_REQUIRED = 'MONTHLY_INCOME_REQUIRED';
  /**
   * @description Error code for a missing support option.
   */
  public static final String SUPPORT_OPTION_REQUIRED = 'SUPPORT_OPTION_REQUIRED';
  /**
   * @description Error code for an unavailable support option.
   */
  public static final String SUPPORT_OPTION_UNAVAILABLE = 'SUPPORT_OPTION_UNAVAILABLE';
  /**
   * @description Error code for a missing grant configuration.
   */
  public static final String GRANT_CONFIGURATION_NOT_FOUND = 'GRANT_CONFIGURATION_NOT_FOUND';
  /**
   * @description Error code for a disbursement option total that is too low.
   */
  public static final String DISBURSEMENT_OPTION_TOTAL_TOO_LOW = 'DISBURSEMENT_OPTION_TOTAL_TOO_LOW';
  /**
   * @description Error code for a disbursement option with no months configured.
   */
  public static final String DISBURSEMENT_OPTION_NO_MONTHS = 'DISBURSEMENT_OPTION_NO_MONTHS';
  /**
   * @description Error code for a failed REST callout.
   */
  public static final String REST_CALLOUT_FAILED = 'REST_CALLOUT_FAILED';
  /**
   * @description Error code for an unexpected error.
   */
  public static final String UNEXPECTED_ERROR = 'UNEXPECTED_ERROR';
  /**
   * @description Error code for an unexpected null error.
   */
  public static final String UNEXPECTED_ERROR_NULL = 'UNEXPECTED_ERROR_NULL';

  /**
   * @description Resolves an error message using the Auto_getMessage Flow.
   * Skips the Flow when the code is blank and returns the default message.
   * Also returns the default message when the Flow output varT_MessageText is blank.
   * @param code Error code passed to the Flow input varT_code.
   * @param defaultMessage Fallback message used when the code or Flow message is blank.
   * @return The non-blank Flow message, or defaultMessage when the code or Flow message is blank.
   */
  public static String getMessage(String code, String defaultMessage) {
    if (String.isBlank(code)) {
      return defaultMessage;
    }
    Flow.Interview.Auto_getMessage interview = new Flow.Interview.Auto_getMessage(
      new Map<String, Object>{ 'varT_code' => code }
    );
    interview.start();

    String messageText = (String) interview.getVariableValue(
      'varT_MessageText'
    );
    return String.isBlank(messageText) ? defaultMessage : messageText;
  }

  /**
   * @description Provides client messages for phone, postal code, and unexpected errors.
   * @return A map of supported client error codes to their fallback messages.
   */
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
