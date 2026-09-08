@IsTest
private class GrantExceptionServiceTest {
  @IsTest
  static void blankCodeReturnsFallbackWithoutQueryingFlow() {
    Test.startTest();
    Integer beforeQueries = Limits.getQueries();
    for (String code : new List<String>{ null, '', '   ' }) {
      Assert.areEqual(
        'Fallback',
        GrantExceptionService.getMessage(code, 'Fallback')
      );
    }
    Assert.areEqual(null, GrantExceptionService.getMessage(null, null));
    Assert.areEqual(
      beforeQueries,
      Limits.getQueries(),
      'Blank codes must skip the Flow lookup.'
    );
    Test.stopTest();
  }

  @IsTest
  static void missingCodeReturnsSuppliedFallback() {
    Test.startTest();
    Assert.areEqual(
      'Missing message',
      GrantExceptionService.getMessage('UNKNOWN_CODE', 'Missing message')
    );
    Assert.areEqual(
      null,
      GrantExceptionService.getMessage('UNKNOWN_CODE', null)
    );
    Test.stopTest();
  }

  @IsTest
  static void configuredMessageOverridesFallback() {
    insert new Grant_Message__c(
      Name = 'PHONE_INVALID',
      Message_Text__c = 'Configured phone message'
    );
    Test.startTest();
    String result = GrantExceptionService.getMessage(
      GrantExceptionService.PHONE_INVALID,
      'Fallback'
    );
    Test.stopTest();
    Assert.areEqual('Configured phone message', result);
  }

  @IsTest
  static void clientMessagesHaveExactFallbackContract() {
    Test.startTest();
    Map<String, String> result = GrantExceptionService.getClientMessages();
    Test.stopTest();
    Assert.areEqual(
      new Map<String, String>{
        'PHONE_INVALID' => 'Phone must use Singapore format 65 6812 3456.',
        'POSTAL_CODE_INVALID' => 'Mailing Postal Code must be a 6 digit number.',
        'UNEXPECTED_ERROR' => 'Unexpected error.',
        'UNEXPECTED_ERROR_NULL' => 'Unexpected error(null).'
      },
      result
    );
  }

  @IsTest
  static void clientMessagesMixConfiguredAndFallbackValues() {
    insert new List<Grant_Message__c>{
      new Grant_Message__c(
        Name = 'PHONE_INVALID',
        Message_Text__c = 'Configured phone'
      ),
      new Grant_Message__c(
        Name = 'POSTAL_CODE_INVALID',
        Message_Text__c = 'Configured postal'
      ),
      new Grant_Message__c(
        Name = 'UNEXPECTED_ERROR',
        Message_Text__c = 'Configured unexpected'
      )
    };
    Test.startTest();
    Map<String, String> result = GrantExceptionService.getClientMessages();
    Test.stopTest();
    Assert.areEqual(
      new Map<String, String>{
        'PHONE_INVALID' => 'Configured phone',
        'POSTAL_CODE_INVALID' => 'Configured postal',
        'UNEXPECTED_ERROR' => 'Configured unexpected',
        'UNEXPECTED_ERROR_NULL' => 'Unexpected error(null).'
      },
      result
    );
  }
}
