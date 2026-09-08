List<ContactBulk__c> records = [
    SELECT Id
    FROM ContactBulk__c
    LIMIT 10000
];

delete records;

System.debug('Jumlah record dihapus: ' + records.size());