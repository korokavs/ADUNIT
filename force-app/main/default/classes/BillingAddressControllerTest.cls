@isTest private class BillingAddressControllerTest {

    @isTest public static void billingAddressControllerTest(){
        
        Account currentAccount = new Account();
        currentAccount.Name = 'CURRENT_ACCOUNT';
        currentAccount.BillingStreet = 'CURRENT_STREET';
        insert currentAccount;
        currentAccount = [SELECT Name, Billing_Account__c, BillingAddress, ParentId FROM Account WHERE Id = :currentAccount.Id];
        
        Contact contact = new Contact();
        contact.LastName = 'CHILD_BILLING_CONTACT';
        insert contact;
        contact = [SELECT LastName FROM Contact WHERE Id = :contact.Id];
        
        Account childAccount = new Account();
        childAccount.Name = 'CHILD_ACCOUNT';
        childAccount.ParentId = currentAccount.Id;
        childAccount.BillingStreet = 'CHILD_STREET';
        insert childAccount;
        childAccount = [SELECT Name, Billing_Account__c, BillingAddress, ParentId FROM Account WHERE Id = :childAccount.Id];
        
        contact.AccountId = childAccount.Id;
        update contact;
        childAccount.Billing_Contact__c = contact.Id;
        update childAccount;
        
        Contract contract = new Contract();
        contract.AccountId = currentAccount.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 1;
		insert contract;
        contract = [SELECT Status FROM Contract WHERE Id = :contract.Id];
        contract.Status = 'Activated';
        update contract;
        
        Order order = new Order();
        order.AccountId = currentAccount.Id;
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        order.ContractId = contract.Id;
        insert order;
        order = [SELECT Status, BillingAddress, BillToContactId FROM Order WHERE Id = :order.Id];
        update order;
        
  		Test.startTest(); 
        BillingAddressController controller = new BillingAddressController(new ApexPages.StandardController(currentAccount)); 
        String address = controller.nameAndAddress(childAccount);
        controller.getAddress();
        controller.setSelectAddr(address);
        controller.changeAddress();
        Test.stopTest();
        
        currentAccount = [SELECT Id, Name, Billing_Account__c, BillingAddress, ParentId FROM Account WHERE Id = :currentAccount.Id];
        childAccount = [SELECT Id, Name, Billing_Account__c, Billing_Contact__c, BillingAddress, ParentId FROM Account WHERE Id = :childAccount.Id];
        order = [SELECT Id, Status, Billing_Account__c, BillingAddress, BillToContactId FROM Order WHERE Id = :order.Id];
        contact = [SELECT Id, LastName FROM Contact WHERE Id = :contact.Id];
      	
        System.assertEquals(currentAccount.Billing_Account__c, childAccount.Id);
        System.assertEquals(childAccount.BillingAddress.getStreet(), order.BillingAddress.getStreet());
        System.assertEquals(childAccount.BillingAddress.getCITY(), order.BillingAddress.getCity());
        System.assertEquals(childAccount.Id, order.Billing_Account__c);
        System.assertEquals(childAccount.Billing_Contact__c, order.BillToContactId);
        System.assert(controller.addressIsEmpty(new Address()) == true);
        Contact contact2 = new Contact();
        contact2.LastName = 'TEST';
		System.assert(controller.firstNameAndLastName(contact2) == contact2.LastName);
   		Address addressTest;
        System.assert(controller.addressToString(addressTest) == '');
        currentAccount.BillingStreet = null;
        System.assertNotEquals(controller.nameAndAddress(currentAccount), currentAccount.Name);
     
        
    }
        @isTest public static void billingAddressControllerTest2(){
       
        Account currentAccount = new Account();
        currentAccount.Name = 'CURRENT_ACCOUNT';
        currentAccount.BillingStreet = 'CURRENT_STREET';
        insert currentAccount;
        currentAccount = [SELECT Name, Billing_Account__c, BillingAddress, ParentId FROM Account WHERE Id = :currentAccount.Id];
        
        
        Contract contract = new Contract();
        contract.AccountId = currentAccount.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 1;
		insert contract;
        contract = [SELECT Status FROM Contract WHERE Id = :contract.Id];
        contract.Status = 'Activated';
        update contract;
        
        Order order = new Order();
        order.AccountId = currentAccount.Id;
        order.EffectiveDate = Date.today();
        order.Status = 'Draft';
        order.ContractId = contract.Id;
        insert order;
        order = [SELECT Status, BillingAddress, BillToContactId FROM Order WHERE Id = :order.Id];
        update order;
        
  		Test.startTest(); 
        BillingAddressController controller = new BillingAddressController(new ApexPages.StandardController(currentAccount)); 
        String address = controller.nameAndAddress(currentAccount);
        controller.getAddress();
        controller.setSelectAddr(address);
        controller.changeAddress();
        Test.stopTest();
        
        currentAccount = [SELECT Id, Name, Billing_Account__c, BillingAddress, ParentId FROM Account WHERE Id = :currentAccount.Id];
        order = [SELECT Id, Status, Billing_Account__c, BillingAddress, BillToContactId FROM Order WHERE Id = :order.Id];

        System.assertEquals(currentAccount.Billing_Account__c, null);
        System.assertEquals(currentAccount.BillingAddress.getStreet(), order.BillingAddress.getStreet());
        System.assertEquals(currentAccount.Id, order.Billing_Account__c);
        System.assert(controller.addressIsEmpty(new Address()) == true);
    }
       
    
}