public virtual class TestFactory {
    
    static public SObject build( String objectType, Boolean buildAndInsert ) {
        Type customType = Type.forName( getFactoryNameForObject( objectType ) );
        TestFactory instance = (TestFactory)customType.newInstance();
        if ( buildAndInsert ) {
            return instance.insertInstance();
        } 
        return instance.buildInstance();
    }

    @TestVisible 
    static private String getFactoryNameForObject( String objectType ) {   
        return 'TestFactory_' + objectType.capitalize();
    }

    public virtual SObject insertInstance(){
        return null;
    }

    public virtual SObject buildInstance(){
        return null;
    }
}