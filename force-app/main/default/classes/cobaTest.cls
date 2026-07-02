@IsTest
private class cobaTest {
    private class AccountPayloadCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('GET', request.getMethod());
            System.assertEquals('application/json', request.getHeader('Accept'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"id":1,"name":"Leanne Graham","username":"Bret","email":"Sincere@april.biz"}');
            return response;
        }
    }

    private class FailedAccountPayloadCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setBody('{"message":"Server error"}');
            return response;
        }
    }

    @IsTest
    static void getAccountsWithActiveOpportunitiesReturnsOnlyMatchingAccounts() {
        Account activeAccount = new Account(Name = 'Active Opportunity Account');
        Account closedAccount = new Account(Name = 'Closed Opportunity Account');
        Account accountWithoutOpportunity = new Account(Name = 'No Opportunity Account');
        insert new List<Account>{ activeAccount, closedAccount, accountWithoutOpportunity };

        insert new List<Opportunity>{
            new Opportunity(
                Name = 'Active Opportunity',
                AccountId = activeAccount.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ),
            new Opportunity(
                Name = 'Closed Opportunity',
                AccountId = closedAccount.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today()
            )
        };

        Test.startTest();
        List<Account> accounts = coba.getAccountsWithActiveOpportunities();
        Test.stopTest();

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        System.assertEquals(1, accounts.size(), 'Only accounts with active opportunities should be returned.');
        System.assert(accountIds.contains(activeAccount.Id), 'Account with an active opportunity should be returned.');
        System.assert(!accountIds.contains(closedAccount.Id), 'Account with only closed opportunities should not be returned.');
        System.assert(!accountIds.contains(accountWithoutOpportunity.Id), 'Account without opportunities should not be returned.');
    }

    @IsTest
    static void parseAccountPayloadDeserializesJsonBody() {
        coba.SampleAccountPayload payload = coba.parseAccountPayload(
            '{"id":1,"name":"Leanne Graham","username":"Bret","email":"Sincere@april.biz"}'
        );

        System.assertEquals('1', payload.id);
        System.assertEquals('Leanne Graham', payload.name);
        System.assertEquals('Bret', payload.username);
        System.assertEquals('Sincere@april.biz', payload.email);
    }

    @IsTest
    static void parseAccountPayloadAllowsMissingId() {
        coba.SampleAccountPayload payload = coba.parseAccountPayload(
            '{"name":"No Id","username":"missing","email":"missing@example.com"}'
        );

        System.assertEquals(null, payload.id);
        System.assertEquals('No Id', payload.name);
        System.assertEquals('missing', payload.username);
        System.assertEquals('missing@example.com', payload.email);
    }

    @IsTest
    static void getAccountPayloadFromRestReturnsDeserializedResponse() {
        Test.setMock(HttpCalloutMock.class, new AccountPayloadCalloutMock());

        Test.startTest();
        coba.SampleAccountPayload payload = coba.getAccountPayloadFromRest('https://jsonplaceholder.typicode.com/users/1');
        Test.stopTest();

        System.assertEquals('1', payload.id);
        System.assertEquals('Leanne Graham', payload.name);
        System.assertEquals('Bret', payload.username);
        System.assertEquals('Sincere@april.biz', payload.email);
    }

    @IsTest
    static void getAccountPayloadFromRestRejectsUnsuccessfulResponse() {
        Test.setMock(
            HttpCalloutMock.class,
            new FailedAccountPayloadCalloutMock()
        );

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            coba.getAccountPayloadFromRest(
                'https://jsonplaceholder.typicode.com/users/1'
            );
        } catch (coba.RestCalloutException exceptionRecord) {
            exceptionThrown = true;
            System.assert(
                exceptionRecord.getMessage().contains('status 500'),
                'REST failures should include the response status.'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'Unsuccessful REST responses should throw a custom exception.'
        );
    }

    @IsTest
    static void publishSampleAccountEventPublishesPlatformEvent() {
        Account account = new Account(Name = 'Event Account');
        insert account;

        Test.startTest();
        Id eventId = coba.publishSampleAccountEvent(account.Id, account.Name, 'Account was processed.');
        Test.stopTest();

        System.assertNotEquals(null, eventId, 'Published platform event should return an event id.');
    }
}
