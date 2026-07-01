trigger ContactTrigger on Contact (
    before insert,
    before update,
    after insert,
    after update
) {
    ContactTriggerHandler handler = new ContactTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }

        if (Trigger.isUpdate) {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
