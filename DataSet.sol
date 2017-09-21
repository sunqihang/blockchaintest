 pragma solidity ^0.4.10;

library DataSet { 
  struct AgentMap {
        address agentAddr;        
        uint loanAmt;  
        uint collateralAmt;
    }

    struct FeeMap {
        string fee;
        uint loanAmt;  
        uint collateralAmt;
        address[] agentList;        
        mapping (address => AgentMap) byAgent;  
    }

// Client data structure

    struct ClientBroker {
        address brokerAddr;        
        string[] feeList;
        address[] agentList;
        mapping (string => FeeMap) byFee;
        mapping (address => AgentMap) byAgent;        
    }

    struct ClientSecurity {
        string cusip;
        uint totalAvail;
        uint totalOnLoan;
        address[] brokerList;
        mapping (address => ClientBroker) byBroker;
    }

    struct Client {
        string acctName;
        address acctAddress;
        uint usdBalance;
        string[] securityList;
        mapping (string => ClientSecurity) bySecurity;
    }        
   
//Broker data structure 

    struct BrokerSecurity {
        string cusip;
        string[] feeList;
        mapping (string => FeeMap) byFee;
    }

    struct Broker {
        string acctName;
        address acctAddress;
        //address[]  clientList;
        string[] securityList;
        mapping (string => BrokerSecurity) bySecurity;
    }    
    
    
//Agent data structure
    struct AgentSecurity {
        string cusip;
        uint loanAmt;
        uint collateralAmt;
    }

    struct BrokerMap {
        address brokerAddr;
        string[] securityList;
		address[]  clientList;
        mapping (address => uint) byClient;		
        mapping (string => AgentSecurity) bySecurity;
    }

    struct Agent {
        string acctName;
        address acctAddress;
        address[] brokerList;
        mapping(address => BrokerMap) brokerMap;
    }
// Manager Structure



    struct secAvailAddress {
       string cusip;
       address[] addressList;
    }

    
}