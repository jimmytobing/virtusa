public with sharing class coba {
  public coba() {
  }

  public class SampleAccountPayload {
    public String id;
    public String name;
    public String username;
    public String email;
  }

  public class RestCalloutException extends Exception {
  }

  public class PlatformEventPublishException extends Exception {
  }

  public static List<Account> getAccountsWithActiveOpportunities() {
    return [
      SELECT Id, Name
      FROM Account
      WHERE
        Id IN (
          SELECT AccountId
          FROM Opportunity
          WHERE IsClosed = FALSE AND AccountId != NULL
        )
      ORDER BY Name
    ];
  }

  public static SampleAccountPayload parseAccountPayload(String jsonBody) {
    Map<String, Object> rawPayload = (Map<String, Object>) JSON.deserializeUntyped(
      jsonBody
    );
    SampleAccountPayload payload = new SampleAccountPayload();
    payload.id = rawPayload.containsKey('id') && rawPayload.get('id') != null
      ? String.valueOf(rawPayload.get('id'))
      : null;
    payload.name = (String) rawPayload.get('name');
    payload.username = (String) rawPayload.get('username');
    payload.email = (String) rawPayload.get('email');
    return payload;
  }

  public static SampleAccountPayload getAccountPayloadFromRest(
    String endpoint
  ) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('GET');
    request.setHeader('Accept', 'application/json');

    HttpResponse response = new Http().send(request);

    if (response.getStatusCode() < 200 || response.getStatusCode() >= 300) {
      throw new RestCalloutException(
        GrantExceptionService.formatMessage(
          GrantExceptionService.REST_CALLOUT_FAILED,
          'REST callout failed with status {0}',
          new List<String>{ String.valueOf(response.getStatusCode()) }
        )
      );
    }

    return parseAccountPayload(response.getBody());
  }

  public static Id publishSampleAccountEvent(
    Id accountId,
    String accountName,
    String message
  ) {
    Sample_Account_Event__e accountEvent = new Sample_Account_Event__e(
      Account_Id__c = accountId == null ? null : String.valueOf(accountId),
      Account_Name__c = accountName,
      Message__c = message
    );

    Database.SaveResult result = EventBus.publish(accountEvent);

    if (!result.isSuccess()) {
      throw new PlatformEventPublishException(
        result.getErrors()[0].getMessage()
      );
    }

    return result.getId();
  }
}
