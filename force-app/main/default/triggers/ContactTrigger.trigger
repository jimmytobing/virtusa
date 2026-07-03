trigger ContactTrigger on Contact(before insert, before update, after insert) {
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
  }
}
