public with sharing class BillBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    //public List<Id> receivesBillByEmail = new List<Id>();
    public Set<Id> receivesBillByEmail = new Set<Id>();
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //this is a method that will query for all accounts that are active and have a value
        //for Bill_By_Email__c (Account.Active__c = \'Yes\' AND Bill_By_Email != null)
        //using the Database.getQueryLocator(String) method. Return the result of this method.
        //Hint: be sure to escape the single quotes surrounding \'Yes\' in your dynamic query!
        //query for the following fields:
        //Id, Bill_By_Email__c
      
        BillAPI.getBills();
        String queryStr = 'SELECT Id,name,Bill_By_Email__c FROM Account WHERE Active__c =\'Yes\' AND Bill_By_Email__c = true';
        return Database.getQueryLocator(queryStr);
      
    }

    public void execute(Database.BatchableContext bc, List<Account> scope){
        //this is a method that will process the queried for records by preparing
        //a list of account Ids (this.receivesBillByEmail) to carry over to the finish method.
        //we will do this by iterating over scope and checking whether Bill_By_Email__c == TRUE.
        //This method will also call our BillAPI.getBills() method.
        for(Account acc:scope){
            this.receivesBillByEmail.add(acc.Id);
        }
		//BillAPI.getBills();
		
    }

    public void finish(Database.BatchableContext bc){
        //this is the final method of the class, that will be called after all processing in the
        //start and execute methods is complete. We will use this method to send an email to each
        //customer in the receivesBillByEmail list. First, we must query for the recently created bills for
        //each account with the following nested query:
        //system.debug(this.receivesBillByEmail);
        List<Account> accLst = [SELECT Id,Email__c,(SELECT Id FROM Bills__r ORDER BY CreatedDate DESC) 
                                FROM Account WHERE Id IN :this.receivesBillByEmail];   
        Map<Id,Id> billMap = new Map<Id,Id>();
        Map<Id,String> emailMap = new Map<Id,String>();
        for(Account acc:accLst){
            billMap.put(acc.id,acc.Bills__r[0].Id);
            emailMap.put(acc.id,acc.Email__c);
        }
        //Next, we are going to prepare to call our BillEmailer.sendEmails(Map<String, Blob> emailsWithBills)
        //method. The String in the map, which we'll call sendMap,will be the Account.Email__c field result, and the Blob
        //will be the PDF attachment we are sending. We will achieve this by iterating over the keyset for
        //billMap, putting the email from the account in the key of the key-value pair, and use the following
        //to generate a PDF for each bill Id in the value of the key-value pair:
        //PageReference pageRef = new PageReference('/apex/BillVFP?id=' + [BILLID]);
        //Blob pdfBlob = pageRef.getContentAsPDF();
        //hint: you'll need to use the .get() method of the Map class a couple of times here.
        Map<String,Blob> pdfMap = new Map<String,Blob>();
        for(Id accId:billMap.keySet()){
            string email = emailMap.get(accId);
            PageReference pageRef = new PageReference('/apex/BillVFP?id=' + billMap.get(accId));
            Blob pdfBlob = pageRef.getContentAsPDF();
            pdfMap.put(email,pdfBlob);
        }

        //finally, we will call our BillEmailer.sendEmails(sendMap) method. Remember, this method is VOID,
        //so there will be no return value;
        BillEmailer.sendEmails(pdfMap); 
         
    }
}