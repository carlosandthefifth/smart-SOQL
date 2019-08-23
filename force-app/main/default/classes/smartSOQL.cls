/*
        PROGRAMMER: DANIEL GUSTAFSON

        NAME: smartSOQL

        PURPOSE:
            Wrapper functions that use SOQL functions as base to query intelligently and adapt to governor limits 

        VERSION NOTES:
            1.0 - just runs basic SOQL queries    
*/
public with sharing class smartSOQL {

    private static String queryStr;
    public static List<String> fields {get; set;}
    public static String objectName {get; set;}
    public static String filter {get; set;}

    public enum SOQLstage {FIELDS, OBJECTNAME, FILTER}

    
    // internal methods
    private static String buildQuery(List<String> fields, string objectName, String filter) {
        // Creates the query to be used 
        String queryStr = 'SELECT ';

        try {
            for (String field : fields) {
                // add the fields that we want
                queryStr = queryStr + field + ','; 
            }
            
            queryStr = queryStr.removeEnd(','); // remove the last comma

            queryStr = queryStr + ' FROM ' + objectname; // adding the object we are looking at

            if ((filter != '') && (filter != null)) {
                // Apply filters
                queryStr = queryStr + ' WHERE ' + filter ;
                system.debug('**building filter');
                system.debug('filter: ' + filter);
                system.debug('queryStr: ' + queryStr);
            }
        } catch (Exception e) {
            system.debug('**inside buildQuery**');
            system.debug('built query: ' + queryStr);
            System.debug('Exception in buildQuery: ' + e.getMessage());
        }
        system.debug('return form buildQuery: ' + queryStr);
        return queryStr;
    }

    private static void desconstructQuery(String queryStr) {
        /*
             Takes a full SOQL query.  Breaks it into its parts and then assigns those parts to internal variables
        */

        SOQLstage stage = SOQLstage.FIELDS; // track parsing position
        fields = new List<String>();  
        // takes a full query string, breaks it down to its seperate parts and initializes internal variables
        List<String> parts = queryStr.split('\\s*(=>|,|\\s)\\s*');
        
        try {
            for (String part : parts) {
                system.debug('part: ' + part);
                // Where are we in parsing this string
                if (part.toUpperCase() == 'SELECT') continue; // skip SELECT we add it at the begining anyway
                if (part.toUpperCase() == 'FROM') {
                    stage = SOQLstage.OBJECTNAME;
                    continue; // skip adding from
                }
                if (part.toUpperCase() == 'WHERE') { 
                    stage = SOQLstage.FILTER;
                    continue; // skip adding where
                }   

                switch on stage {
                    when FIELDS {
                        // grab fields
                        fields.add(part);
                    }
                    when OBJECTNAME {
                        // grab object
                        objectName = part;
                    }
                    when FILTER {
                        // grab FILTERS
                        String manStr; // holder for string manipulation
                        integer indexStr; // string search position

                        system.debug('adding filter: ' + part);
                        
                        manStr = part;
                        indexStr = manStr.indexOf('=');

                        if ((manStr.indexOf(indexStr+1) != '\'') || (manStr.indexOf(indexStr+1) != ':')) {
                            // we have a filter with a constant but not quote 
                            // like SELECT id FROM account WHERE id=0018A00000J2jYTQAZ
                            // expected would be SELECT id FROM account WHERE id='0018A00000J2jYTQAZ'
                            manStr = manStr.indexOf(indexStr) + '\'' + manStr.right(indexStr) + '\'';  // add single quotes
                        }

                        system.debug('manStr: ' + manStr);
                        if (filter == null) 
                            filter = manStr;
                        else
                            filter = filter + ' ' + manStr;

                    }
                }        
            }
        } catch (Exception e) {
            // We errored out  - what do the query parts look like?
            system.debug('**inside desconstructQuery**');
            for (String field : fields) {
                system.debug('exeption field: ' + field);
            }
            
            system.debug('exception objectName: ' + objectName);

            system.debug('exception filter: ' + filter);

            system.debug('Exception in desconstructQuery: ' + e.getMessage());
        }
    }

    private static List<SObject> execute() {
        String theQuery = buildQuery(fields, objectName, filter);
        List<SObject> results = new List<SObject>();
        
        try {
            system.debug('theQuery: ' + theQuery);
            results = database.query(theQuery);
        } catch (Exception e) {
            system.debug('**inside execute**');
            system.debug('Exception in desconstructQuery: ' + e.getMessage());
            system.debug('theQuery: ' + theQuery);
        } 

        return results;
    }

    public static List<SObject> smartSOQL(List<String> fields, string objectName, String filter) {
            List<SObject> rows = new List<SObject>();
            
            rows = execute();  // run the query
            
            system.debug('queryStr: ' + queryStr);
            return rows;
    }

    public static List<SObject> smartSOQL(String queryStr) {
            List<SObject> rows = new List<SObject>();

            desconstructQuery(queryStr);
            
            rows = execute();

            return rows;
    }
    
}