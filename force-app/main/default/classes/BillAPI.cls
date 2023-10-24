public with sharing class BillAPI {
     
    public static List<Bill__c> getBills() {
        //start by creating an HttpRequest object and set the endpoint and method.
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint('callout:Billing_API');
            httpReq.setMethod('GET');
        //set up an Http object and an HTTPResponse Object and use the .getBody() method here.
            Http htp = new Http();
            HTTPResponse httpRes = new HTTPResponse();
            httpRes = htp.send(httpReq);
        //Use the following to deserialize the JSON response into a wrapper class:
            //system.debug(httpRes.getStatusCode());
            //system.debug(httpRes.getStatus());
          List<BillWrapper> bwList = new List<BillWrapper>();
          if(httpRes.getStatusCode() == 200){
            //system.debug(httpRes.getBody());
             bwList =(List<BillWrapper>)JSON.deserialize(httpRes.getBody(),List<BillWrapper>.class);
            //system.debug(bwList);
          }
            
        //create a list of bills to insert
          List<Bill__c> billsToBeInserted = new  List<Bill__c>();
        
        //query for active accounts (Active__c = 'Yes')
          List<Account> activeAccLst = [select Name,Id from Account Where Active__c = 'Yes'];
       
        //create an active account map in the form of Map<String, Id>
        //iterate over the list of active accounts, and use the .put() method of the Map class
        // to insert the account name and Id as the key value pair.
           Map<String, Id> activeAccMap = new Map<String, Id>();
           for(Account acc:activeAccLst){
              activeAccMap.put(acc.Name,acc.Id);
           }
        //iterate over the list of BillWrappers, bwList, and create a new bill in each iteration.
        //Match the new bill fields with the properties of the BillWrapper class
         if(bwList.size() > 0){
           for(BillWrapper bw : bwList){
                Bill__c billToInsert = new Bill__c();
                billToInsert.Bill_Id__c = bw.billId;
                billToInsert.Account__c = activeAccMap.get(bw.accountName);
                billToInsert.Balance__c = Decimal.valueOf(bw.balance.replace('$', ''));
                billsToBeInserted.add(billToInsert);
                }  
          //finally, insert the new bills list  
               upsert billsToBeInserted Bill_Id__c;
        }

      // query bill records
   		 List<Bill__c> billLst = [select Bill_Id__c,Account__c,Balance__c from Bill__c];
         if(billLst.size()>0)
    		return billLst;
         else 
     		return null;
    }

    /*this is what's known as a wrapper class. A wrapper class
    //allows us to create an instance of a class with the properties
    //we specify. In this case, we are creating a class that will hold
    //the properties for the BillId, AccountName, and Balance, which will
    //be populated from the JSON structure that is stored in our external
    //data source. Once we get the body of our HTTP callout, we will use
    //the following line of code to transform the response body (responseBody)
    //into a list of instances of our wrapper class, BillWrapper:
    //
    //List<BillWrapper> bwList = (List<BillWrapper>)JSON.deserialize(responseBody, List<BillWrapper>.class);
    //
    //once we have a list of BillWrapper objects (bwList), we will iterate over the
    //bwList, instantiate a new Bill__c object record, and assign the values of the
    //BillWrapper properties to the fields on the Bill__c record.*/
    
       public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }
}