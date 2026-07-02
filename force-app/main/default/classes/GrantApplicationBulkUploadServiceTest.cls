@IsTest
private class GrantApplicationBulkUploadServiceTest {
  @IsTest
  static void bulkUploadedApplicationsCreateContactsAndDisbursements() {
    List<Grant_Application__c> applications = new List<Grant_Application__c>{
      createUploadApplication(
        'Andrew',
        'Lee',
        '65 8989 8989',
        '123456',
        2000,
        'Option 1'
      ),
      createUploadApplication(
        'Bella',
        'Yew',
        '65 9000 0001',
        '654321',
        2000,
        'Option 2'
      )
    };

    Test.startTest();
    insert applications;
    Test.stopTest();

    List<Grant_Application__c> savedApplications = [
      SELECT
        Applicant__c,
        Grant_Type__c,
        Requested_Amount__c,
        Status__c,
        Current_Stage__c
      FROM Grant_Application__c
      WHERE Id IN :applications
      ORDER BY Applicant_Phone__c
    ];
    List<Contact> applicants = [
      SELECT
        FirstName,
        LastName,
        Phone,
        MailingPostalCode,
        Monthly_Income__c,
        Annual_Income__c,
        Support_Option__c,
        Grant_Application__c
      FROM Contact
      WHERE Phone IN ('65 8989 8989', '65 9000 0001')
      ORDER BY Phone
    ];

    System.assertEquals(2, applicants.size());
    System.assertEquals('Andrew', applicants[0].FirstName);
    System.assertEquals('Lee', applicants[0].LastName);
    System.assertEquals('123456', applicants[0].MailingPostalCode);
    System.assertEquals(2000, applicants[0].Monthly_Income__c);
    System.assertEquals(24000, applicants[0].Annual_Income__c);
    System.assertEquals('Option_One', applicants[0].Support_Option__c);

    System.assertEquals(2, savedApplications.size());
    System.assertEquals(applicants[0].Id, savedApplications[0].Applicant__c);
    System.assertEquals(
      applicants[0].Grant_Application__c,
      savedApplications[0].Id
    );
    System.assertEquals('Option One', savedApplications[0].Grant_Type__c);
    System.assertEquals(1500, savedApplications[0].Requested_Amount__c);
    System.assertEquals(
      GrantConstants.STATUS_PENDING,
      savedApplications[0].Status__c
    );
    System.assertEquals('Submitted', savedApplications[0].Current_Stage__c);

    System.assertEquals(applicants[1].Id, savedApplications[1].Applicant__c);
    System.assertEquals('Option Two', savedApplications[1].Grant_Type__c);
    System.assertEquals(1800, savedApplications[1].Requested_Amount__c);
    System.assertEquals(
      9,
      [
        SELECT COUNT()
        FROM Grant_Disbursement__c
        WHERE Grant_Applicantion__c IN :applications
      ],
      'Option 1 should create 3 rows and Option 2 should create 6 rows.'
    );
  }

  @IsTest
  static void uploadUpdatesExistingContactMatchedByPhone() {
    Contact existingApplicant = new Contact(
      FirstName = 'Old',
      LastName = 'Applicant',
      Phone = '65 9000 0002',
      MailingPostalCode = '111111',
      Monthly_Income__c = 500,
      Annual_Income__c = 6000,
      Support_Option__c = 'Option_One'
    );
    insert existingApplicant;

    Grant_Application__c application = createUploadApplication(
      'Charlie',
      'Loong',
      '65 9000 0002',
      '234253',
      2000,
      'Option 1'
    );

    Test.startTest();
    insert application;
    Test.stopTest();

    Contact savedApplicant = [
      SELECT
        FirstName,
        LastName,
        MailingPostalCode,
        Monthly_Income__c,
        Annual_Income__c,
        Grant_Application__c
      FROM Contact
      WHERE Phone = '65 9000 0002'
      LIMIT 1
    ];
    Grant_Application__c savedApplication = [
      SELECT Applicant__c
      FROM Grant_Application__c
      WHERE Id = :application.Id
    ];

    System.assertEquals(existingApplicant.Id, savedApplicant.Id);
    System.assertEquals('Charlie', savedApplicant.FirstName);
    System.assertEquals('Loong', savedApplicant.LastName);
    System.assertEquals('234253', savedApplicant.MailingPostalCode);
    System.assertEquals(2000, savedApplicant.Monthly_Income__c);
    System.assertEquals(24000, savedApplicant.Annual_Income__c);
    System.assertEquals(existingApplicant.Id, savedApplication.Applicant__c);
    System.assertEquals(application.Id, savedApplicant.Grant_Application__c);
  }

  @IsTest
  static void uploadDoesNotCreateDisbursementsWhenIncomeExceedsThreshold() {
    Grant_Application__c application = createUploadApplication(
      'High',
      'Income',
      '65 9000 0004',
      '345678',
      3001,
      'Option 1'
    );

    Test.startTest();
    insert application;
    Test.stopTest();

    Contact savedApplicant = [
      SELECT Monthly_Income__c, Annual_Income__c, Grant_Application__c
      FROM Contact
      WHERE Phone = '65 9000 0004'
      LIMIT 1
    ];

    System.assertEquals(3001, savedApplicant.Monthly_Income__c);
    System.assertEquals(36012, savedApplicant.Annual_Income__c);
    System.assertEquals(application.Id, savedApplicant.Grant_Application__c);
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Grant_Disbursement__c
        WHERE Grant_Applicantion__c = :application.Id
      ],
      'Applicants above the active income threshold should not receive disbursements.'
    );
  }

  @IsTest
  static void invalidUploadedApplicationFailsWithoutCreatingRelatedRecords() {
    Grant_Application__c invalidApplication = createUploadApplication(
      'Invalid',
      'Applicant',
      '90000003',
      'ABC123',
      1000,
      'Option 1'
    );

    Test.startTest();
    Database.SaveResult result = Database.insert(invalidApplication, false);
    Test.stopTest();

    System.assertEquals(false, result.isSuccess());
    System.assertEquals(
      0,
      [SELECT COUNT() FROM Contact WHERE LastName = 'Applicant'],
      'Invalid rows should not create Contacts.'
    );
    System.assertEquals(0, [SELECT COUNT() FROM Grant_Disbursement__c]);
  }

  @IsTest
  static void invalidUploadedApplicationsCoverRequiredFieldBranches() {
    List<Grant_Application__c> invalidApplications = new List<Grant_Application__c>{
      createUploadApplication(
        null,
        'Missing First',
        '65 9000 0005',
        '123456',
        1000,
        'Option 1'
      ),
      createUploadApplication(
        'Missing Last',
        null,
        '65 9000 0006',
        '123456',
        1000,
        'Option 1'
      ),
      createUploadApplication(
        'Missing',
        'Income',
        '65 9000 0007',
        '123456',
        null,
        'Option 1'
      ),
      createUploadApplication(
        'Invalid',
        'Income',
        '65 9000 0008',
        '123456',
        -1,
        'Option 1'
      ),
      createUploadApplication(
        'Missing',
        'Support',
        '65 9000 0009',
        '123456',
        1000,
        null
      ),
      createUploadApplication(
        'Unavailable',
        'Support',
        '65 9000 0010',
        '123456',
        1000,
        'Unavailable Option'
      )
    };

    Test.startTest();
    List<Database.SaveResult> results = Database.insert(
      invalidApplications,
      false
    );
    Test.stopTest();

    for (Database.SaveResult result : results) {
      System.assertEquals(false, result.isSuccess());
      System.assertEquals(1, result.getErrors().size());
    }
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Contact
        WHERE
          Phone IN (
            '65 9000 0005',
            '65 9000 0006',
            '65 9000 0007',
            '65 9000 0008',
            '65 9000 0009',
            '65 9000 0010'
          )
      ]
    );
  }

  @IsTest
  static void publicHandlersIgnoreEmptyInputs() {
    Test.startTest();
    GrantApplicationBulkUploadService.validateBeforeInsert(null);
    GrantApplicationBulkUploadService.validateBeforeInsert(
      new List<Grant_Application__c>()
    );
    GrantApplicationBulkUploadService.processAfterInsert(null);
    GrantApplicationBulkUploadService.processAfterInsert(
      new List<Grant_Application__c>()
    );
    GrantApplicationBulkUploadService.processAfterUpdate(
      new List<Grant_Application__c>(),
      null
    );
    Test.stopTest();

    System.assertEquals(0, [SELECT COUNT() FROM Grant_Application__c]);
  }

  private static Grant_Application__c createUploadApplication(
    String firstName,
    String lastName,
    String phone,
    String postalCode,
    Decimal monthlyIncome,
    String supportOption
  ) {
    return new Grant_Application__c(
      Applicant_First_Name__c = firstName,
      Applicant_Last_Name__c = lastName,
      Applicant_Phone__c = phone,
      Mailing_Postal_Code__c = postalCode,
      Monthly_Income__c = monthlyIncome,
      Support_Option__c = supportOption,
      Reason__c = 'Bulk uploaded application.'
    );
  }
}
