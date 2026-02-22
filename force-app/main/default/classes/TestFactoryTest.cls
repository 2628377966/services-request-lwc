@isTest
public class TestFactoryTest {
    @isTest
    static void testBuildWithInsert() {
        SObject result = TestFactory.build('Account', true);

        System.assertNotEquals(null, result, 'The result should not be null');
        System.assert(result instanceof Account, 'The result should be an instance of Account');
    }

    @isTest
    static void testBuildWithoutInsert() {
        SObject result = TestFactory.build('Account', false);

        System.assertNotEquals(null, result, 'The result should not be null');
        System.assert(result instanceof Account, 'The result should be an instance of Contact');
    }

    @isTest
    static void testGetFactoryNameForObject() {
        String result1 = TestFactory.getFactoryNameForObject('Account');
        String result2 = TestFactory.getFactoryNameForObject('Lead');

        System.assertEquals('TestFactory_Account', result1, 'The factory name for Account should be correct');
        System.assertEquals('TestFactory_Lead', result2, 'The factory name for Lead should be correct');
    }

    @isTest
    static void testInsertInstance() {
        TestFactory instance = new TestFactory();
        SObject result = instance.insertInstance();
        System.assertEquals(null, result, 'The result should be null');
    }

    @isTest
    static void testBuildInstance() {
        TestFactory instance = new TestFactory();
        SObject result = instance.buildInstance();
        System.assertEquals(null, result, 'The result should be null');
    }
}