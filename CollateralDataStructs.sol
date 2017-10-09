 pragma solidity ^0.4.10;

library CollateralDataStructs { 
    struct AgentMap {
        address agentAddr;        
        uint loanAmt;  
        uint collateralAmt;
    }

    struct RateMap {
        string rate;
        uint loanAmt;  
        uint collateralAmt;
        address[] agentList;        
        mapping (address => AgentMap) byAgent;  
    }

// Client data structure

    struct ClientBroker {
        address brokerAddr;        
        string[] rateList;
        address[] agentList;
        mapping (string => RateMap) byRate;
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
        string[] securityList;
        mapping (string => ClientSecurity) bySecurity;
    }        
   
//Broker data structure 

    struct BrokerSecurity {
        string cusip;
        string[] rateList;
        mapping (string => RateMap) byRate;
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

// Avail Structure
    struct secAvailAddress {
       string cusip;
       address[] addressList;
    }
    
// Transaction Data Structures

    struct Transaction {
        address brokerAddr; 
        address clientAddr; 
        address agentAddr; 
        string cusip;
        string rate;       
        uint loanAmt;  
        uint collateralAmt;
        uint dateTime;
    }
}