@IsTest
private class GrantPortalControllerTest {

    @IsTest
    static void supportOptionsReturnActiveMetadataOptions() {
        GrantPortalController controller = new GrantPortalController();

        Test.startTest();
        List<SelectOption> options = controller.getSupportOptions();
        Test.stopTest();

        System.assertEquals('', options[0].getValue());
        System.assert(options.size() > 1);
    }

    @IsTest
    static void submitAddsErrorMessageForInvalidRequest() {
        GrantPortalController controller = new GrantPortalController();
        controller.firstName = 'Guest';

        Test.startTest();
        PageReference result = controller.submit();
        Test.stopTest();

        System.assertEquals(null, result);
        System.assertEquals(1, ApexPages.getMessages().size());
        System.assertEquals(
            ApexPages.Severity.ERROR,
            ApexPages.getMessages()[0].getSeverity()
        );
    }

    @IsTest
    static void submitCreatesApplicationForValidRequest() {
        GrantPortalController controller = new GrantPortalController();
        controller.firstName = 'Guest';
        controller.lastName = 'Applicant';
        controller.phone = '65 6812 3490';
        controller.mailingPostalCode = '123456';
        controller.monthlyIncome = 1000;
        controller.supportOption = 'Option_One';
        controller.reason = 'Guest portal submission.';

        Test.startTest();
        PageReference result = controller.submit();
        Test.stopTest();

        System.assertEquals(null, result);
        System.assertEquals(1, ApexPages.getMessages().size());
        System.assertEquals(
            ApexPages.Severity.CONFIRM,
            ApexPages.getMessages()[0].getSeverity()
        );
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Grant_Application__c
                WHERE Reason__c = 'Guest portal submission.'
            ]
        );
        System.assertEquals(null, controller.firstName);
        System.assertEquals(null, controller.supportOption);
    }
}
