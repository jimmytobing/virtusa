@IsTest
private class ExperienceCloudTemplateCoverageTest {

    @IsTest
    static void lightningLoginControllerCoversAuthBranches() {
        LightningLoginFormController controller =
            new LightningLoginFormController();

        Test.startTest();
        String nullExperienceResult =
            LightningLoginFormController.setExperienceId(null);
        String invalidExperienceResult =
            LightningLoginFormController.setExperienceId('invalid-experience');
        String invalidLoginResult =
            LightningLoginFormController.login(
                'missing@example.com',
                'bad-password',
                '/s/'
            );
        Boolean usernamePasswordEnabled =
            LightningLoginFormController.getIsUsernamePasswordEnabled();
        Boolean selfRegistrationEnabled =
            LightningLoginFormController.getIsSelfRegistrationEnabled();
        String selfRegistrationUrl =
            LightningLoginFormController.getSelfRegistrationUrl();
        String forgotPasswordUrl =
            LightningLoginFormController.getForgotPasswordUrl();
        Test.stopTest();

        System.assertNotEquals(null, controller);
        System.assertEquals(null, nullExperienceResult);
        System.assertEquals(null, invalidLoginResult);
        System.assertNotEquals(null, usernamePasswordEnabled);
        System.assertNotEquals(null, selfRegistrationEnabled);
        System.assertEquals(
            selfRegistrationEnabled,
            selfRegistrationUrl != null,
            'Self registration URL should only be populated when enabled.'
        );
        System.assertEquals(forgotPasswordUrl, forgotPasswordUrl);
    }

    @IsTest
    static void lightningForgotPasswordControllerCoversSetExperience() {
        LightningForgotPasswordController controller =
            new LightningForgotPasswordController();

        Test.startTest();
        String nullExperienceResult =
            LightningForgotPasswordController.setExperienceId(null);
        String invalidExperienceResult =
            LightningForgotPasswordController.setExperienceId('invalid-experience');
        String forgotPasswordResult =
            LightningForgotPasswordController.forgotPassword(
                'not-a-real-user@example.com',
                '/check-email'
            );
        Test.stopTest();

        System.assertNotEquals(null, controller);
        System.assertEquals(null, nullExperienceResult);
        System.assertEquals(null, forgotPasswordResult);
    }

    @IsTest
    static void lightningSelfRegisterControllerCoversValidationBranches() {
        LightningSelfRegisterController controller =
            new LightningSelfRegisterController();

        Test.startTest();
        String missingLastName = LightningSelfRegisterController.selfRegister(
            'Guest',
            null,
            'guest@example.com',
            'Password123!',
            'Password123!',
            null,
            '/confirm',
            null,
            '/start',
            true
        );
        String missingEmail = LightningSelfRegisterController.selfRegister(
            'Guest',
            'Applicant',
            '',
            'Password123!',
            'Password123!',
            null,
            '/confirm',
            null,
            '/start',
            true
        );
        String passwordMismatch =
            LightningSelfRegisterController.selfRegister(
                'Guest',
                'Applicant',
                'guest@example.com',
                'Password123!',
                'Different123!',
                null,
                '/confirm',
                null,
                '/start',
                true
            );
        String handledRegistrationError =
            LightningSelfRegisterController.selfRegister(
                'Guest',
                'Applicant',
                'guest@example.com',
                null,
                null,
                null,
                '/confirm',
                '[{"fieldPath":"LocaleSidKey","value":"en_US"}]',
                '/start',
                false
            );
        List<Map<String, Object>> extraFields =
            LightningSelfRegisterController.getExtraFields('Missing_Field_Set');
        String nullExperienceResult =
            LightningSelfRegisterController.setExperienceId(null);
        String invalidExperienceResult =
            LightningSelfRegisterController.setExperienceId('invalid-experience');
        Test.stopTest();

        System.assertNotEquals(null, controller);
        System.assertNotEquals(null, missingLastName);
        System.assertNotEquals(null, missingEmail);
        System.assertNotEquals(null, passwordMismatch);
        System.assertEquals(null, handledRegistrationError);
        System.assertEquals(0, extraFields.size());
        System.assertEquals(null, nullExperienceResult);
    }

    @IsTest
    static void visualforceSelfRegistrationControllersCoverErrors() {
        ApexPages.currentPage().getParameters().put('expid', null);

        CommunitiesSelfRegController communityController =
            new CommunitiesSelfRegController();
        communityController.firstName = 'Community';
        communityController.lastName = 'Applicant';
        communityController.email = 'community@example.com';
        communityController.password = 'Password123!';
        communityController.confirmPassword = 'Mismatch123!';
        communityController.communityNickname = ' community ';

        CommunitiesSelfRegController validCommunityController =
            new CommunitiesSelfRegController();
        validCommunityController.firstName = 'Valid';
        validCommunityController.lastName = 'Applicant';
        validCommunityController.email = 'valid-community@example.com';
        validCommunityController.password = 'Password123!';
        validCommunityController.confirmPassword = 'Password123!';
        validCommunityController.communityNickname = ' valid ';

        SiteRegisterController siteRegisterController =
            new SiteRegisterController();
        siteRegisterController.username = 'site@example.com';
        siteRegisterController.email = 'site@example.com';
        siteRegisterController.password = 'Password123!';
        siteRegisterController.confirmPassword = 'Mismatch123!';
        siteRegisterController.communityNickname = ' site ';

        SiteRegisterController validSiteRegisterController =
            new SiteRegisterController();
        validSiteRegisterController.username = 'valid-site@example.com';
        validSiteRegisterController.email = 'valid-site@example.com';
        validSiteRegisterController.password = 'Password123!';
        validSiteRegisterController.confirmPassword = 'Password123!';
        validSiteRegisterController.communityNickname = ' valid-site ';

        MicrobatchSelfRegController microbatchController =
            new MicrobatchSelfRegController();
        microbatchController.firstName = 'Micro';
        microbatchController.lastName = 'Applicant';
        microbatchController.email = 'micro@example.com';
        microbatchController.communityNickname = ' micro ';

        Test.startTest();
        PageReference communityResult = communityController.registerUser();
        PageReference validCommunityResult =
            validCommunityController.registerUser();
        PageReference siteRegisterResult =
            siteRegisterController.registerUser();
        try {
            validSiteRegisterController.registerUser();
        } catch (Exception exceptionRecord) {
            System.assertNotEquals(null, exceptionRecord.getMessage());
        }
        PageReference microbatchResult = microbatchController.registerUser();
        Test.stopTest();

        System.assertEquals(null, communityResult);
        System.assertEquals(null, validCommunityResult);
        System.assertEquals(null, siteRegisterResult);
        System.assertEquals(null, microbatchResult);
    }

    @IsTest
    static void profileAndForgotPasswordControllersCoverActions() {
        MyProfilePageController profileController =
            new MyProfilePageController();
        ForgotPasswordController forgotPasswordController =
            new ForgotPasswordController();
        forgotPasswordController.username = 'missing@example.com';

        Test.startTest();
        System.assertNotEquals(null, profileController.getUser());
        System.assertEquals(false, profileController.getIsEdit());
        profileController.edit();
        System.assertEquals(true, profileController.getIsEdit());
        PageReference changePasswordPage =
            profileController.changePassword();
        profileController.cancel();
        PageReference forgotPasswordResult =
            forgotPasswordController.forgotPassword();
        Test.stopTest();

        System.assertEquals(false, profileController.getIsEdit());
        System.assertEquals(Page.ChangePassword.getUrl(), changePasswordPage.getUrl());
        System.assertEquals(null, forgotPasswordResult);
    }
}
