public with sharing class GrantUtility {

    /**
     * Returns true if the string is null, empty, or contains only whitespace.
     */
    public static Boolean isBlank(String value) {
        return String.isBlank(value);
    }

    /**
     * Returns true if the object is null.
     */
    public static Boolean isNull(Object value) {
        return value == null;
    }

    /**
     * Generates a unique transaction ID for logging purposes.
     */
    public static String generateTransactionId() {
        return EncodingUtil.convertToHex(
            Crypto.generateDigest(
                'SHA1',
                Blob.valueOf(String.valueOf(Datetime.now().getTime()) + Math.random())
            )
        );
    }
}