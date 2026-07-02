// Anonymous Apex cleanup script for grant demo data.
//
// Run with:
//   sf apex run --file scripts/apex/clean-grant-org-data.apex --target-org <alias>
//
// Re-run this file until the final remaining counts are all 0.
// The script intentionally limits DML rows per execution to avoid governor limits.

Integer maxDmlRowsPerRun = 9000;
Integer maxRowsPerStep = 1000;
Integer dmlRowsUsed = 0;
Integer totalSuccess = 0;
Integer totalErrors = 0;

System.debug('Starting cleanup. DML row budget: ' + maxDmlRowsPerRun);

// Break circular/custom lookups first so parent/child deletes are less likely to fail.
Integer rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query(
        'SELECT Id, Applicant__c FROM Grant_Application__c WHERE Applicant__c != null LIMIT ' + rowsToProcess
    );
    for (SObject recordItem : records) {
        recordItem.put('Applicant__c', null);
    }
    Database.SaveResult[] results = Database.update(records, false);
    dmlRowsUsed += records.size();
    for (Database.SaveResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to clear Grant_Application__c.Applicant__c on ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Cleared Grant_Application__c.Applicant__c rows: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query(
        'SELECT Id, Grant_Application__c FROM Contact WHERE Grant_Application__c != null LIMIT ' + rowsToProcess
    );
    for (SObject recordItem : records) {
        recordItem.put('Grant_Application__c', null);
    }
    Database.SaveResult[] results = Database.update(records, false);
    dmlRowsUsed += records.size();
    for (Database.SaveResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to clear Contact.Grant_Application__c on ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Cleared Contact.Grant_Application__c rows: ' + records.size());
}

// Delete child/dependent records before parents.
rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Task LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Task ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Task rows attempted: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Grant_Disbursement__c LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Grant_Disbursement__c ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Grant_Disbursement__c rows attempted: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Opportunity LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Opportunity ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Opportunity rows attempted: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Integration_Error__c LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Integration_Error__c ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Integration_Error__c rows attempted: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Grant_Application__c LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Grant_Application__c ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Grant_Application__c rows attempted: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Contact LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Contact ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Contact rows attempted: ' + records.size());
}

rowsToProcess = Math.min(maxRowsPerStep, maxDmlRowsPerRun - dmlRowsUsed);
if (rowsToProcess > 0) {
    List<SObject> records = Database.query('SELECT Id FROM Account LIMIT ' + rowsToProcess);
    Database.DeleteResult[] results = Database.delete(records, false);
    dmlRowsUsed += records.size();
    for (Database.DeleteResult resultItem : results) {
        if (resultItem.isSuccess()) {
            totalSuccess++;
        } else {
            totalErrors++;
            System.debug('Failed to delete Account ' + resultItem.getId() + ': ' + resultItem.getErrors()[0].getMessage());
        }
    }
    System.debug('Deleted Account rows attempted: ' + records.size());
}

System.debug('Cleanup DML rows used: ' + dmlRowsUsed);
System.debug('Cleanup successes: ' + totalSuccess);
System.debug('Cleanup errors: ' + totalErrors);

System.debug('Remaining Task: ' + Database.countQuery('SELECT COUNT() FROM Task'));
System.debug('Remaining Grant_Disbursement__c: ' + Database.countQuery('SELECT COUNT() FROM Grant_Disbursement__c'));
System.debug('Remaining Opportunity: ' + Database.countQuery('SELECT COUNT() FROM Opportunity'));
System.debug('Remaining Integration_Error__c: ' + Database.countQuery('SELECT COUNT() FROM Integration_Error__c'));
System.debug('Remaining Grant_Application__c: ' + Database.countQuery('SELECT COUNT() FROM Grant_Application__c'));
System.debug('Remaining Contact: ' + Database.countQuery('SELECT COUNT() FROM Contact'));
System.debug('Remaining Account: ' + Database.countQuery('SELECT COUNT() FROM Account'));
