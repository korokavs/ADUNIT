public with sharing class ShippingAddressController {
    private Account account;
    private Account shippingAccount;
    private Contact shippingContact;
    
    Map<String, Account> addressToAccountMap = new Map<String, Account>();
    
    public ShippingAddressController(ApexPages.StandardController controller){
        this.account = (Account)controller.getRecord();
        account = [SELECT Id, Name, ParentId, ShippingAddress, Shipping_Account__c, Shipping_Contact__c 
                   FROM Account 
                   WHERE Id = :account.Id];
         if(account.Shipping_Account__c != null){
            shippingAccount = [SELECT Id, Name, ParentId, ShippingAddress, Shipping_Account__c, Shipping_Contact__c 
                              FROM Account 
                              WHERE Id = :account.Shipping_Account__c];
            if(ShippingAccount.Shipping_Contact__c != null){
                shippingContact = [SELECT LastName, FirstName
                                 FROM Contact
                                 WHERE Id = :shippingAccount.Shipping_Contact__c];}
        } else if(account.Shipping_Contact__c != null){
            shippingContact = [SELECT LastName, FirstName
                                 FROM Contact
                                 WHERE Id = :account.Shipping_Contact__c];}
    }
    
    // Selected Option is current Address
    String selectAddr{ get; set;} 
    public String getSelectAddr(){
        return SelectAddr;
    }
    public void setSelectAddr(String selectAddr){
        this.selectAddr = selectAddr;
    }
    
    //Show Shipping Data
    String shippToAccount{get; set;}
    public String getShippToAccount(){
        if(shippingAccount != null){return shippingAccount.Name;}
        else{return account.Name;}
    }    
    String shippToContact{get; set;}
    public String getShippToContact(){
        String name;
        if(shippingContact != null){name = firstNameAndLastName(shippingContact);}
        return name;
    }
    String shippToAddress{get; set;}
    public String getShippToAddress(){
        String address = '';
        if(account.ShippingAddress != null && addressIsEmpty(account.ShippingAddress) != true)
        {address = addressToString(account.shippingAddress);}
        
        if(account.Shipping_Account__c != null && shippingAccount.ShippingAddress != null && addressIsEmpty(ShippingAccount.ShippingAddress) != true)
        {address = addressToString(shippingAccount.shippingAddress);}
        return address;
    }
    
    // Options to show in Select bar
    public List<SelectOption> getAddress(){    
        List<SelectOption> options = new List<SelectOption>(); 
        List<Account> allNeededAccounts = accountsToShow(account); 
        String address;
        for(Account account_i : allNeededAccounts){
            if(account_i.ShippingAddress != null){
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
        List<Order> orders = [SELECT Id, ShippingAddress
                             FROM Order
                             WHERE AccountId = :account.Id];
        Account acc = [SELECT Shipping_Contact__c FROM Account WHERE Id = :chosenAccount.Id];
        account.Shipping_Account__c = chosenAccount.Id;
        Address shippingAddress = chosenAccount.ShippingAddress;
        for(Order order_i : orders){
      	  order_i.ShippingStreet = shippingAddress.getStreet();
       	  order_i.ShippingPostalCode = shippingAddress.getPostalCode();
       	  order_i.ShippingCity = shippingAddress.getCity();
      	  order_i.ShippingCountry = shippingAddress.getCountry();
      	  order_i.ShippingState = shippingAddress.getState();
      	  order_i.ShippingLatitude = shippingAddress.getLatitude();
      	  order_i.ShippingLongitude = shippingAddress.getLongitude();
          order_i.ShippingGeocodeAccuracy = shippingAddress.getGeocodeAccuracy();
          order_i.Shipping_Account__c = chosenAccount.Id;
          if(acc.Shipping_Contact__c == null){order_i.ShipToContactId = null;}
		  else{order_i.ShipToContactId = acc.Shipping_Contact__c;}
        }
        update orders;
        if(account.Id != chosenAccount.Id) {account.Shipping_Account__c = chosenAccount.Id;}
        else {account.Shipping_Account__c = null;}
        update account;
    }
    
    // Custom methods for help ===
    private List<Account> accountsToShow(Account currentAccount){
        List<Account> all = new List<Account>();
        
        List<Account> parents = [SELECT Name, ParentId, ShippingAddress, Billing_Contact__c
                                   FROM Account 
                                   WHERE Id = :currentAccount.ParentId];
        List<Account> neighbours = [SELECT Name, ParentId, ShippingAddress, Billing_Contact__c
                                    FROM Account 
                                    WHERE ParentId = :currentAccount.ParentId AND ParentId != NULL AND Id != :currentAccount.Id];
        List<Account> childs = [SELECT Id, Name, ParentId, ShippingAddress, Billing_Contact__c
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
            			+ addressToString(account.ShippingAddress);    
      
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
           state ==null){isEmpty = true;}
        else{isEmpty = false;}
        return isEmpty;
    }
          
}