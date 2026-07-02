public with sharing class GrantConfigurationRepository {
  /**
   * Retrieves the active configuration for a grant type.
   */
  public static Grant_Configuration__mdt getByGrantType(String grantType) {
    Grant_Configuration__mdt selectedConfig;

    for (Grant_Configuration__mdt config : getActiveConfigurations()) {
      if (config.Grant_Type__c != grantType) {
        continue;
      }

      if (
        selectedConfig == null ||
        comparePriority(config, selectedConfig) < 0
      ) {
        selectedConfig = config;
      }
    }

    return selectedConfig;
  }

  /**
   * Retrieves all active grant configurations.
   */
  public static List<Grant_Configuration__mdt> getActiveConfigurations() {
    List<Grant_Configuration__mdt> configs = new List<Grant_Configuration__mdt>();

    for (
      Grant_Configuration__mdt config : Grant_Configuration__mdt.getAll()
        .values()
    ) {
      if (config.Active__c == true) {
        configs.add(config);
      }
    }

    return configs;
  }

  private static Integer comparePriority(
    Grant_Configuration__mdt leftConfig,
    Grant_Configuration__mdt rightConfig
  ) {
    if (leftConfig.Priority__c == rightConfig.Priority__c) {
      return 0;
    }

    return leftConfig.Priority__c < rightConfig.Priority__c ? -1 : 1;
  }
}
