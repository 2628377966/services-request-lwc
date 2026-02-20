@isTest
public class OJButtonsHelperTest {

    @isTest
    static void testGetFormButtonLabels_ValidBrand() {
        Test.startTest();
        List<OJ_Button_Label__mdt> result = OJButtonsHelper.getFormButtonLabels('Ezidebit');
        Test.stopTest();

        System.assertNotEquals(result.size(), 0, 'The result should not be empty.');
        System.assertEquals(result[0].DeveloperName, 'Ezidebit0', 'The first record should be Ezidebit0.');
        System.assertEquals(result[1].DeveloperName, 'Ezidebit1', 'The second record should be Ezidebit1.');
    }

    @isTest
    static void testGetFormButtonLabels_NoResultsFound() {
        Test.startTest();
        try {
            OJButtonsHelper.getFormButtonLabels('NonExistentBrand');
            System.assert(false, 'Expected a CustomException to be thrown.');
        } catch (CustomException e) {
            System.assert(e.getMessage().contains('No labels found for the brand'), 'The exception message should contain the correct text.');
        }
        Test.stopTest();
    }
}