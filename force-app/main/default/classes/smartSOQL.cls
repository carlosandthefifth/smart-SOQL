public with sharing class smartSOQL {

    private static String queryStr;
    public smartSOQL(List<String> fields, string objectName, List<String> filters) {
        queryStr = 'SELECT ';

        for (String field : fields) {
            queryStr = queryStr + field + ',';
        }
        
        queryStr = queryStr.left(queryStr.length() - 2) + queryStr.right(1);

        queryStr = queryStr + ' ' + objectname;

        if (!filters.isEmpty()) {
            queryStr = queryStr + ' ';
            for (String filter : filters) {
                queryStr = queryStr + filter + ',';
            }
            queryStr = queryStr + ' ' + objectname;
        }
            system.debug('query: ' + query);
    }
}