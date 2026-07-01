trigger GrantApplicationTrigger on Grant_Application__c (

    before insert,
    before update,
    after insert,
    after update

) {

    GrantApplicationTriggerHandler handler =
        new GrantApplicationTriggerHandler();

    if (Trigger.isBefore) {

        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            handler.beforeUpdate(
                Trigger.new,
                Trigger.oldMap
            );
        }

    }

    if (Trigger.isAfter) {

        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            handler.afterUpdate(
                Trigger.new,
                Trigger.oldMap
            );
        }

    }

}