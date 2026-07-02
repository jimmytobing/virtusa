@IsTest
private class GrantExceptionServiceTest {
  @IsTest
  static void getMessageReturnsFallbacksAndFormatsPlaceholders() {
    System.assertEquals(
      'Fallback message.',
      GrantExceptionService.getMessage(null, 'Fallback message.')
    );
    System.assertEquals(
      'Missing metadata fallback.',
      GrantExceptionService.getMessage(
        'UNKNOWN_ERROR_CODE',
        'Missing metadata fallback.'
      )
    );

    System.assertEquals(
      'Hello Ada Lovelace',
      GrantExceptionService.formatMessage(
        'UNKNOWN_ERROR_CODE',
        'Hello {0} {1}',
        new List<String>{ 'Ada', 'Lovelace' }
      )
    );
    System.assertEquals(
      'Hello ',
      GrantExceptionService.formatMessage(
        'UNKNOWN_ERROR_CODE',
        'Hello {0}',
        new List<String>{ null }
      )
    );
    System.assertEquals(
      'No replacements.',
      GrantExceptionService.formatMessage(
        'UNKNOWN_ERROR_CODE',
        'No replacements.',
        null
      )
    );
  }

  @IsTest
  static void getClientMessagesReturnsExpectedDefaults() {
    Map<String, String> messagesByCode = GrantExceptionService.getClientMessages();

    System.assertEquals(4, messagesByCode.size());
    System.assertEquals(
      'Phone must use Singapore format 65 6812 3456.',
      messagesByCode.get(GrantExceptionService.PHONE_INVALID)
    );
    System.assertEquals(
      'Mailing Postal Code must be a 6 digit number.',
      messagesByCode.get(GrantExceptionService.POSTAL_CODE_INVALID)
    );
    System.assertEquals(
      'Unexpected error.',
      messagesByCode.get(GrantExceptionService.UNEXPECTED_ERROR)
    );
    System.assertEquals(
      'Unexpected error(null).',
      messagesByCode.get(GrantExceptionService.UNEXPECTED_ERROR_NULL)
    );
  }
}
