public with sharing class GrantDisbursementService {

    public static Boolean bypassContactTrigger = false;

    public static void recalculateDisbursements(
        Id contactId,
        Grant_Support_Option__mdt option
    ) {
        if (contactId == null || option == null) {
            return;
        }

        Contact contactRecord = new Contact(
            Id = contactId,
            Support_Option__c = option.DeveloperName,
            Monthly_Income__c = 0
        );

        recalculateForContacts(
            new List<Contact>{ contactRecord },
            new Map<String, Grant_Support_Option__mdt>{
                option.DeveloperName => option
            }
        );
    }

    public static void recalculateForContacts(List<Contact> contacts) {
        if (contacts == null || contacts.isEmpty()) {
            return;
        }

        recalculateForContacts(contacts, getActiveOptionsByDeveloperName());
    }

    private static void recalculateForContacts(
        List<Contact> contacts,
        Map<String, Grant_Support_Option__mdt> optionsByDeveloperName
    ) {
        Map<Id, Grant_Support_Option__mdt> optionsByContactId =
            new Map<Id, Grant_Support_Option__mdt>();

        for (Contact contactRecord : contacts) {
            if (
                contactRecord.Id == null ||
                String.isBlank(contactRecord.Support_Option__c) ||
                contactRecord.Monthly_Income__c == null
            ) {
                continue;
            }

            Grant_Support_Option__mdt option =
                optionsByDeveloperName.get(contactRecord.Support_Option__c);

            if (option != null) {
                optionsByContactId.put(contactRecord.Id, option);
            }
        }

        if (optionsByContactId.isEmpty()) {
            return;
        }

        Map<Id, List<Grant_Disbursement__c>> disbursementsByContactId =
            new Map<Id, List<Grant_Disbursement__c>>();

        for (Grant_Disbursement__c disbursement : [
            SELECT
                Id,
                Grant_Applicant__c,
                Amount_to_be_disbursed__c,
                Grant_is_disbursed__c,
                Disbursed_Date__c
            FROM Grant_Disbursement__c
            WHERE Grant_Applicant__c IN :optionsByContactId.keySet()
            ORDER BY Disbursed_Date__c
        ]) {
            if (!disbursementsByContactId.containsKey(disbursement.Grant_Applicant__c)) {
                disbursementsByContactId.put(
                    disbursement.Grant_Applicant__c,
                    new List<Grant_Disbursement__c>()
                );
            }

            disbursementsByContactId.get(
                disbursement.Grant_Applicant__c
            ).add(disbursement);
        }

        List<Grant_Disbursement__c> disbursementsToDelete =
            new List<Grant_Disbursement__c>();
        List<Grant_Disbursement__c> disbursementsToInsert =
            new List<Grant_Disbursement__c>();
        Date today = Date.today();

        for (Id contactId : optionsByContactId.keySet()) {
            Grant_Support_Option__mdt option =
                optionsByContactId.get(contactId);
            List<Grant_Disbursement__c> existingDisbursements =
                disbursementsByContactId.containsKey(contactId)
                    ? disbursementsByContactId.get(contactId)
                    : new List<Grant_Disbursement__c>();

            Decimal totalReceived = 0;
            Integer receivedMonths = 0;

            for (Grant_Disbursement__c disbursement : existingDisbursements) {
                Boolean hasBeenDisbursed =
                    disbursement.Grant_is_disbursed__c == true &&
                    disbursement.Disbursed_Date__c <= today;

                if (hasBeenDisbursed) {
                    totalReceived += disbursement.Amount_to_be_disbursed__c;
                    receivedMonths++;
                } else {
                    disbursementsToDelete.add(disbursement);
                }
            }

            Decimal newTotalAmount =
                option.Monthly_Amount__c * option.Duration_Months__c;

            if (totalReceived > newTotalAmount) {
                throw new GrantException(
                    'Support Option cannot be changed because the total disbursed amount is greater than the new option total.'
                );
            }

            Integer durationMonths = option.Duration_Months__c.intValue();
            Integer remainingMonths = durationMonths - receivedMonths;
            Decimal remainingAmount = newTotalAmount - totalReceived;

            if (remainingAmount > 0 && remainingMonths <= 0) {
                throw new GrantException(
                    'Support Option cannot be changed because there are no remaining months available.'
                );
            }

            if (remainingAmount <= 0) {
                continue;
            }

            Decimal monthlyAmount = remainingAmount / remainingMonths;
            Date disbursementDate = firstDayOfNextMonth(today);

            for (Integer monthNumber = 1; monthNumber <= remainingMonths; monthNumber++) {
                disbursementsToInsert.add(new Grant_Disbursement__c(
                    Grant_Applicant__c = contactId,
                    Amount_to_be_disbursed__c = monthlyAmount,
                    Grant_is_disbursed__c = true,
                    Disbursed_Date__c = disbursementDate.addMonths(monthNumber - 1),
                    Support_Option__c = option.MasterLabel,
                    Sequence_Number__c = receivedMonths + monthNumber
                ));
            }
        }

        if (!disbursementsToDelete.isEmpty()) {
            delete disbursementsToDelete;
        }

        if (!disbursementsToInsert.isEmpty()) {
            insert disbursementsToInsert;
        }
    }

    private static Map<String, Grant_Support_Option__mdt>
        getActiveOptionsByDeveloperName()
    {
        Map<String, Grant_Support_Option__mdt> optionsByDeveloperName =
            new Map<String, Grant_Support_Option__mdt>();

        for (Grant_Support_Option__mdt option : [
            SELECT
                DeveloperName,
                MasterLabel,
                Monthly_Amount__c,
                Duration_Months__c,
                Active__c
            FROM Grant_Support_Option__mdt
            WHERE Active__c = TRUE
        ]) {
            optionsByDeveloperName.put(option.DeveloperName, option);
            optionsByDeveloperName.put(option.MasterLabel, option);
        }

        return optionsByDeveloperName;
    }

    private static Date firstDayOfNextMonth(Date sourceDate) {
        return Date.newInstance(
            sourceDate.year(),
            sourceDate.month(),
            1
        ).addMonths(1);
    }
}
