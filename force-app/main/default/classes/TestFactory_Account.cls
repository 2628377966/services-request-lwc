@isTest
public class TestFactory_Account extends TestFactory  {
		
	public override SObject buildInstance(){
        return buildAccount();
    }

    public override SObject insertInstance(){
        return insertAccount();
    }

	 public static Account insertAccountWithDetails(){ 
    	Account myAccount = buildAccountWithDetails();
    	insert myAccount;
    	return myAccount;
    }
    
    public static Account buildAccountWithDetails(){
    	Account myAccount = buildAccount();
    	myAccount.Client_Code__c = '123-456-789';
    	return myAccount;
    }
       
    public static Account insertAccount(){ 
    	Account myAccount = buildAccount();
    	insert myAccount;
    	return myAccount;
    }
    
    public static Account buildAccount(){
    	Account myAccount = new Account();
    	myAccount.name = 'testName';
    	return myAccount;
    }
}