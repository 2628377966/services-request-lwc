@isTest
public class TestFactory_Opportunity extends TestFactory  {
	
	public override SObject buildInstance(){
        return buildOpportunity();
    }

    public override SObject insertInstance(){
        return insertOpportunity();
    }
    
    public static Opportunity insertOpportunity(Account myAccount){
    	Opportunity myOpportunity = buildOpportunity(myAccount);
    	insert myOpportunity;
    	return myOpportunity;    	
    }
    
    public static Opportunity insertOpportunity(){
    	Opportunity myOpportunity = buildOpportunity();
    	insert myOpportunity;
    	return myOpportunity;    	
    }
    
    public static Opportunity buildOpportunity(){
    	return buildOpportunity(TestFactory_Account.insertAccount());
    }
    
    public static Opportunity buildOpportunity(Account myAccount){
    	Opportunity myOpportunity = new Opportunity();
    	myOpportunity.Name= myAccount.Name;
		myOpportunity.StageName='Proposal Stage';
		//myOpportunity.recordTypeId = Utils.getRecordTypeId('Opportunity','Storman');
		myOpportunity.CloseDate=System.today();	
		//myOpportunity.LeadSource = 'Advertising';
		//myOpportunity.Type= 'New Business';
		myOpportunity.Accountid = myAccount.Id;
    	return myOpportunity;
    }
}