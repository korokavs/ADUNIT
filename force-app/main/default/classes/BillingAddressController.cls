public with sharing class BillingAddressController {
    private Account account;
    private Account billingAccount;
    private Contact billingContact;
     
    Map<String, Account> addressToAccountMap = new Map<String, Account>();
       
    public BillingAddressController(ApexPages.StandardController controller){
        this.account = (Account)controller.getRecord();
        account = [SELECT Id, Name, ParentId, BillingAddress, Billing_Account__c, Billing_Contact__c 
                   FROM Account 
                   WHERE Id = :account.Id];
        if(account.Billing_Account__c != null){
            billingAccount = [SELECT Id, Name, ParentId, BillingAddress, Billing_Account__c, Billing_Contact__c 
                              FROM Account 
                              WHERE Id = :account.Billing_Account__c];
            if(billingAccount.Billing_Contact__c != null){
                billingContact = [SELECT Id, LastName, FirstName
                                 FROM Contact
                                 WHERE Id = :billingAccount.Billing_Contact__c];}
        } else if(account.Billing_Contact__c != null){
            billingContact = [SELECT LastName, FirstName
                                 FROM Contact
                                 WHERE Id = :account.Billing_Contact__c];}     
    }
    
    // Selected Option is current Address
    String selectAddr{get; set;} 
    public String getSelectAddr(){
        return SelectAddr;
    }
    public void setSelectAddr(String selectAddr){
        this.selectAddr = selectAddr;
    }
    
    // Show Billing Data
    String billToAccount{get; set;}
    public String getBillToAccount(){
        if(billingAccount != null){return billingAccount.Name;}
        else{return account.Name;}
    }    
    String billToContact{get; set;}
    public String getBillToContact(){
        String name;
        if(billingContact != null){name = firstNameAndLastName(billingContact);}
        return name;
    }
    String billToAddress{get; set;}
    public String getBillToAddress(){
        String address = '';
        if(account.BillingAddress != null && addressIsEmpty(account.BillingAddress) != true)
        {address = addressToString(account.BillingAddress);}
        
        if(account.Billing_Account__c != null && billingAccount.BillingAddress != null && addressIsEmpty(BillingAccount.BillingAddress) != true)
        {address = addressToString(billingAccount.BillingAddress);}
        return address;
    }
    
    // Options to show in Select bar
    public List<SelectOption> getAddress(){    
        List<SelectOption> options = new List<SelectOption>();   
        List<Account> allNeededAccounts = accountsToShow(account);  
        String address;
        for(Account account_i : allNeededAccounts){
            if(account_i.BillingAddress != null){
                address =  nameAndAddress(account_i);
                options.add(new SelectOption(address, address));
                addressToAccountMap.put(address, account_i);  
            }
        }        
        return options;      
    }
    
    // Method which change Address
    public void changeAddress(){
        Account chosenAccount = addressToAccountMap.get(getSelectAddr());
        List<Order> orders = [SELECT Id, BillingAddress, BillToContactId
                              FROM Order
                              WHERE AccountId = :account.Id AND (Status = 'Draft' OR Status = 'Activated')];
        Account acc = [SELECT Billing_Contact__c FROM Account WHERE Id = :chosenAccount.Id];
        account.Billing_Account__c = chosenAccount.Id;
        Address billingAddress = chosenAccount.BillingAddress;
        if(orders.size() > 0){
        for(Order order_i : orders){     
            order_i.BillingStreet = billingAddress.getStreet();
            order_i.BillingPostalCode = billingAddress.getPostalCode();
            order_i.BillingCity = billingAddress.getCity();
            order_i.BillingCountry = billingAddress.getCountry();
            order_i.BillingState = billingAddress.getState();
            order_i.BillingLatitude = billingAddress.getLatitude();
            order_i.BillingLongitude = billingAddress.getLongitude();
            order_i.BillingGeocodeAccuracy = billingAddress.getGeocodeAccuracy(); 
            order_i.Billing_Account__c = chosenAccount.Id; 
            if(acc.Billing_Contact__c == null){order_i.BillToContactId = null;}
			else{order_i.BillToContactId = acc.Billing_Contact__c;}
        }
        update orders;
        }
        if(account.Id != chosenAccount.Id) {account.Billing_Account__c = chosenAccount.Id;}
        else {account.Billing_Account__c = null;}
        update account;
    }
    
    // Custom methods for help ===
    private List<Account> accountsToShow(Account currentAccount){
        List<Account> all = new List<Account>();
        
        List<Account> parents = [SELECT Name, ParentId, BillingAddress, Billing_Contact__c
                                 FROM Account 
                                 WHERE Id = :currentAccount.ParentId];
        List<Account> neighbours = [SELECT Name, ParentId, BillingAddress, Billing_Contact__c
                                    FROM Account 
                                    WHERE ParentId = :currentAccount.ParentId AND ParentId != NULL AND Id != :currentAccount.Id];
        List<Account> childs = [SELECT Id, Name, ParentId, BillingAddress, Billing_Contact__c
                                FROM Account
                                WHERE ParentId = :currentAccount.Id];
        
        all.add(currentAccount);
        all.addAll(parents);
        all.addAll(neighbours);
        all.addAll(childs);
        return all;
    }
    
    public String addressToString(Address address){
        String fullAddress = '';
        if(address !=null){
        String street = address.getStreet();
        String postalCode = address.getPostalCode();
        String city = address.getCity();
        String country = address.getCountry();
        if(street != null){
            fullAddress += street;
            if(postalCode != null || city != null || country != null){fullAddress += ', ';}
        }
        if(postalCode != null){
            fullAddress += postalCode;
            if(city != null || country != null){fullAddress += ', ';}
        }
        if(city != null){
            fullAddress += city;
            if(country != null){fullAddress += ', ';}
        }
        if(country != null){
            fullAddress += country;
        }
            }
        return fullAddress;
    }
    
    public String nameAndAddress(Account account){
        String nameAndAddress;
        
        nameAndAddress = account.Name + ' - ' 
            + addressToString(account.BillingAddress);    
        
        return nameAndAddress;
    }
    
    public String firstNameAndLastName(Contact contact){
        String name = '';
        if(contact != null){
            
            if(contact.FirstName != null){
                name = contact.FirstName + ' ';
            }
            name += contact.LastName;
        } 
        else {name = ' ';}
        return name;
    }
    
    public Boolean addressIsEmpty(Address address){
        Boolean isEmpty;
        String street = address.getStreet();
        String postalCode = address.getPostalCode();
        String city = address.getCity();
        String state = address.getState();
        String country = address.getCountry();
        Double latitude = address.getLatitude();
        Double longitude = address.getLongitude();
        String geocodeAccuracy = address.getGeocodeAccuracy();
        if(street == null &&
           postalCode == null &&
           city == null &&
           country == null &&
           state == null){isEmpty = true;}
        else{isempty = false;}
        return isEmpty;
    }
    
}