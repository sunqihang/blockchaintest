pragma solidity ^0.4.10;
import 'https://github.com/sunqihang/blockchaintest/CollateralDataStructs.sol';
import 'https://github.com/sunqihang/blockchaintest/ConcatStrings.sol';

contract Collateral {
    address private owner;

    mapping (address => uint) acctExists; // NE,agent,Broker,Client
    mapping (address => CollateralDataStructs.Client) clientAcct;
    mapping (address => CollateralDataStructs.Broker) brokerAcct;
    mapping (address => CollateralDataStructs.Agent) agentAcct;

    string[] securityList;
    mapping (string => CollateralDataStructs.secAvailAddress) securitiesAvail;

    uint transactionId = 0;
    CollateralDataStructs.Transaction[] allTransactions;
    mapping (address => uint[]) transactionMap;

// Modifiers

    modifier isType (uint typeOf) { // 0,Agent,Broker,Client
        require(acctExists[msg.sender] == typeOf);
        _;
    }

    modifier acctDNE () {
        require(acctExists[msg.sender] == 0);
        _;
    }

// Events

    // event updateBalance (address toAcctAddr, string cusip, uint balance);
    event transactionOccured(address brokerAddr, address clientAddr, address agentAddr, uint id);

    function updateCollateral(uint transacID, uint totalCollateral) {
        CollateralDataStructs.Transaction storage t = allTransactions[transacID];
        
        int deltaCollateral = int(totalCollateral - t.collateralAmt);
        
        // update client collat info
        CollateralDataStructs.ClientBroker storage bm = clientAcct[t.clientAddr].bySecurity[t.cusip].byBroker[t.brokerAddr];
        bm.byRate[t.rate].loanAmt = uint(int(bm.byRate[t.rate].loanAmt) + deltaCollateral) ;
        bm.byRate[t.rate].collateralAmt = uint(int(bm.byRate[t.rate].collateralAmt)  + deltaCollateral);
        // Update Collateral
        bm.byAgent[t.agentAddr].loanAmt = uint(int(bm.byAgent[t.agentAddr].loanAmt) + deltaCollateral);
        bm.byAgent[t.agentAddr].collateralAmt = uint(int(bm.byAgent[t.agentAddr].collateralAmt)+deltaCollateral);
        //update collateral by rate by agent
        CollateralDataStructs.AgentMap storage rateAgentMap = bm.byRate[t.rate].byAgent[t.agentAddr];
        rateAgentMap.loanAmt = uint(int(rateAgentMap.loanAmt) + deltaCollateral);
        rateAgentMap.collateralAmt =  uint(int(rateAgentMap.collateralAmt) + deltaCollateral);
        
        // update Agent collat info
        CollateralDataStructs.Agent storage a = agentAcct[t.agentAddr];
        //update by client amount
        a.brokerMap[t.brokerAddr].byClient[t.clientAddr] = uint(int(a.brokerMap[t.brokerAddr].byClient[t.clientAddr])+deltaCollateral);
        // Update Security
        CollateralDataStructs.AgentSecurity storage agentSec = a.brokerMap[t.brokerAddr].bySecurity[t.cusip];
        agentSec.loanAmt = uint(int(agentSec.loanAmt)+deltaCollateral);
        agentSec.collateralAmt = uint(int(agentSec.collateralAmt)+deltaCollateral);
        
        //update Broker collat info
        //CollateralDataStructs.Broker storage broker = brokerAcct[t.brokerAddr];
        CollateralDataStructs.RateMap storage brokerRate = brokerAcct[t.brokerAddr].bySecurity[t.cusip].byRate[t.rate];
        // Update Collateral
        brokerRate.loanAmt = uint(int(brokerRate.loanAmt) + deltaCollateral);
        brokerRate.collateralAmt = uint(int(brokerRate.collateralAmt) + deltaCollateral);
        // Update Collateral
        CollateralDataStructs.AgentMap storage brokerAgentMap = brokerRate.byAgent[t.agentAddr];
        brokerAgentMap.loanAmt = uint(int(brokerAgentMap.loanAmt) + deltaCollateral);
        brokerAgentMap.collateralAmt =uint(int(brokerAgentMap.collateralAmt) + deltaCollateral);
    }


// Register Functions
    
    // 1 is Agent, 2 is Broker, 3 is Client
    // Note currently ANYONE can register, this is unsecure
    function addAccount (uint acctType, string acctName) acctDNE() {
        address[] addrInit; // Never init
        string[] stringInit; // Never init
        if (acctType == 1) {
            acctExists[msg.sender] = 1;
            agentAcct[msg.sender] = CollateralDataStructs.Agent(acctName,msg.sender, addrInit);
        } else if (acctType == 2) {
            acctExists[msg.sender] = 2;
            brokerAcct[msg.sender] = CollateralDataStructs.Broker(acctName, msg.sender, stringInit);
        } else if (acctType == 3) {
            acctExists[msg.sender] = 3;
            clientAcct[msg.sender] = CollateralDataStructs.Client(acctName, msg.sender, stringInit);            
        }
    }
        

// Add Availability 

    function addAvailability (string cusip, uint amt) isType(3) {
        CollateralDataStructs.Client storage a = clientAcct[msg.sender];
        CollateralDataStructs.ClientSecurity storage sec = a.bySecurity[cusip];
        if (sha3(sec.cusip) != sha3(cusip)) {
            a.securityList.push(cusip);
            sec.cusip = cusip;
            if (sha3(securitiesAvail[cusip].cusip) != sha3(cusip)) {
                securityList.push(cusip);
                securitiesAvail[cusip].cusip = cusip;
            }  
            securitiesAvail[cusip].addressList.push(msg.sender);
        }
        sec.totalAvail += amt;
        // updateBalance(msg.sender,cusip,sec.totalAvail);        
    }

// Security/Collateral Transfer Functions

    function loanOccur (address clientAddr, string cusip, string loanRate, uint loanAmt, uint collateralAmt, address agentAddr, uint dateTime) returns (uint id) {
        // Validate Addresses & Input
        require(acctExists[agentAddr] == 1);
        require(acctExists[msg.sender] == 2);
        require(acctExists[clientAddr] == 3);
        require(loanAmt > 0);
        require(collateralAmt >= 0);
        // Borrow Security
        updateClient(clientAddr, cusip, msg.sender, loanRate, loanAmt, collateralAmt, agentAddr);
        // Send Collateral
        updateAgent(agentAddr, msg.sender,clientAddr, cusip, loanAmt, collateralAmt);
        // Update Broker Records
        updateBroker(msg.sender, cusip, loanRate, loanAmt, collateralAmt, agentAddr);
        // Update History
        allTransactions.push(CollateralDataStructs.Transaction(msg.sender, clientAddr, agentAddr, cusip, loanRate, loanAmt, collateralAmt, dateTime));
        transactionMap[msg.sender].push(transactionId);
        transactionMap[clientAddr].push(transactionId);
        transactionMap[agentAddr].push(transactionId);
        transactionId += 1;
        // Event
        transactionOccured(msg.sender, clientAddr, agentAddr, (transactionId - 1));
        return (transactionId - 1);
    }

    function updateClient (address clientAddr, string cusip, address brokerAddr, string loanRate, uint loanAmt, uint collateralAmt, address agentAddr) internal {
        CollateralDataStructs.ClientSecurity storage sec = clientAcct[clientAddr].bySecurity[cusip];
        // Check There is Availability
        require((sec.totalOnLoan + loanAmt) <= sec.totalAvail);
        // Update On Loan Total
        sec.totalOnLoan += loanAmt;
        
        //Update Broker
        CollateralDataStructs.ClientBroker storage bm = sec.byBroker[brokerAddr];
        if (bm.brokerAddr == 0) {
            sec.brokerList.push(brokerAddr);
            bm.brokerAddr = brokerAddr;
        }        
        
        // Update Rate
        CollateralDataStructs.RateMap storage rate = bm.byRate[loanRate];
        if (sha3(rate.rate) != sha3(loanRate)) {
            bm.rateList.push(loanRate);
            rate.rate = loanRate;
        }
        rate.loanAmt += loanAmt;
        rate.collateralAmt += collateralAmt;

        // Update Collateral
        CollateralDataStructs.AgentMap storage agentMap = bm.byAgent[agentAddr];
        if (agentMap.agentAddr == 0 ) {
            bm.agentList.push(agentAddr);
            agentMap.agentAddr = agentAddr;
        }
        agentMap.loanAmt += loanAmt;
        agentMap.collateralAmt += collateralAmt;

        CollateralDataStructs.AgentMap storage rateAgentMap = rate.byAgent[agentAddr];
        if (rateAgentMap.agentAddr == 0 ) {
            rate.agentList.push(agentAddr);
            rateAgentMap.agentAddr = agentAddr;
        }
        rateAgentMap.loanAmt += loanAmt;
        rateAgentMap.collateralAmt += collateralAmt;
    }

    function updateAgent (address agentAddr, address brokerAddr,address clientAddr, string cusip, uint loanAmt, uint collateralAmt) internal {
        CollateralDataStructs.Agent storage a = agentAcct[agentAddr];
        // Update Broker
        CollateralDataStructs.BrokerMap storage b = a.brokerMap[brokerAddr];
        if (b.brokerAddr != brokerAddr) {
            a.brokerList.push(brokerAddr);
            b.brokerAddr = brokerAddr;
        }
        //update by client amount
        if (b.byClient[clientAddr] ==0){
            b.clientList.push(clientAddr);
        }
        b.byClient[clientAddr] += collateralAmt;
        
        // Update Security
        CollateralDataStructs.AgentSecurity storage sec = b.bySecurity[cusip];
        if (sha3(sec.cusip) != sha3(cusip)) {
            b.securityList.push(cusip);
            sec.cusip = cusip;
        }
        sec.loanAmt += loanAmt;
        sec.collateralAmt += collateralAmt;
    }

    function updateBroker (address brokerAddr, string cusip, string loanRate, uint loanAmt, uint collateralAmt, address agentAddr) internal {
        CollateralDataStructs.Broker storage b = brokerAcct[brokerAddr];
        // Update Security
        CollateralDataStructs.BrokerSecurity storage sec = b.bySecurity[cusip];
        if (sha3(sec.cusip) != sha3(cusip)) {
            b.securityList.push(cusip);
            sec.cusip = cusip;
        }
        // Update Rate
        CollateralDataStructs.RateMap storage rate = sec.byRate[loanRate];
        if (sha3(rate.rate) != sha3(loanRate)) {
            sec.rateList.push(loanRate);
            rate.rate = loanRate;
        }
        rate.loanAmt += loanAmt;
        rate.collateralAmt += collateralAmt;
        // Update Collateral
        CollateralDataStructs.AgentMap storage agentMap = rate.byAgent[agentAddr];
        if (agentMap.agentAddr == 0 ) {
            rate.agentList.push(agentAddr);
            agentMap.agentAddr = agentAddr;
        }
        agentMap.loanAmt += loanAmt;
        agentMap.collateralAmt += collateralAmt;
    }

// Check Data Functions

    // AGENT cusip is blank
    // CLIENT
    function getBrokerList(string cusip) returns (string brokersListS, address[] brokerAddrs) {
        address[] storage brokersList;
        if (acctExists[msg.sender] == 1) brokersList = agentAcct[msg.sender].brokerList;
        else if (acctExists[msg.sender] == 3) brokersList = clientAcct[msg.sender].bySecurity[cusip].brokerList;

        brokerAddrs = new address[](brokersList.length);
        for(uint i = 0; i < brokersList.length; i++) {
            address broker = brokersList[i];
            brokersListS = ConcatStrings.concatList(brokersListS, brokerAcct[broker].acctName);
            brokerAddrs[i] = broker;
        }
    }
    
    // AGENT paramAddr is the broker address returns (loanAmt, collateralAmt)
    // BROKER paramAddr is blank/0 returns (0, 0)
    // CLIENT paramAddr is blank/0 returns (totalAvail, totalOnLoan)
    function getSec (address paramAddr, bool listOnly) returns (string secList, uint[] ttl1, uint[] ttl2) {
        string[] storage securitysList;
        if (acctExists[msg.sender] == 1) securitysList = agentAcct[msg.sender].brokerMap[paramAddr].securityList;
        else if (acctExists[msg.sender] == 2) securitysList = brokerAcct[msg.sender].securityList;
        else if (acctExists[msg.sender] == 3) securitysList = clientAcct[msg.sender].securityList;

        ttl1 = new uint[](securitysList.length);
        ttl2 = new uint[](securitysList.length);
        for(uint i = 0; i < securitysList.length; i++) {
            secList = ConcatStrings.concatList(secList, securitysList[i]);
            if (!listOnly) {
                (ttl1[i], ttl2[i]) =  getSecTotals(securitysList[i], paramAddr, 0);
            }
        }
    }

    // BROKER cusip is cusip, secAvail (avail, onLoan)
    // Agent paramAddr is brokerAddr, client (0, Collateral)
    function getClients (string cusip, address paramAddr) returns (string clientsList, address[] clientAddrs, uint[] ttl1, uint[] ttl2) {
        address[] storage list; 
        if (acctExists[msg.sender] == 1) list = agentAcct[msg.sender].brokerMap[paramAddr].clientList;
        if (acctExists[msg.sender] == 2) list = securitiesAvail[cusip].addressList;

        clientAddrs = new address[](list.length);    
        ttl1 = new uint[](list.length);
        ttl2 = new uint[](list.length);

        for(uint i = 0; i < list.length; i++) {
            clientAddrs[i] = list[i];            
            (ttl1[i], ttl2[i]) = getSecTotals(cusip, list[i], paramAddr);
            clientsList = ConcatStrings.concatList(clientsList, clientAcct[list[i]].acctName);
        }
    }
    
    // AGENT paramAddr is the broker address returns (loanAmt, collateralAmt)
    // AGENT paramAddr is the client address and paramAddr2 is the broker address returns (0, collateralAmt)
    // BROKER paramAddr is the client address returns  (totalAvail, totalOnLoan)
    // CLIENT paramAddr is blank/0 returns (totalAvail, totalOnLoan)
    function getSecTotals (string cusip, address paramAddr, address paramAddr2) internal returns (uint ttl1, uint ttl2) {
        if (acctExists[msg.sender] == 1 && paramAddr2 != 0 && acctExists[paramAddr2] == 2) {
            return (0, agentAcct[msg.sender].brokerMap[paramAddr2].byClient[paramAddr]);
        } else if (acctExists[msg.sender] == 1) {
            CollateralDataStructs.AgentSecurity storage sec = agentAcct[msg.sender].brokerMap[paramAddr].bySecurity[cusip];
            return (sec.loanAmt, sec.collateralAmt);
        } else if (acctExists[msg.sender] == 2 && paramAddr != 0 && acctExists[paramAddr] == 3) {
            CollateralDataStructs.ClientSecurity storage clientSec = clientAcct[paramAddr].bySecurity[cusip];
            return (clientSec.totalAvail, clientSec.totalOnLoan);
        } else if (acctExists[msg.sender] == 3) {
            CollateralDataStructs.ClientSecurity storage secId = clientAcct[msg.sender].bySecurity[cusip];
            return (secId.totalAvail, secId.totalOnLoan);
        }
    }

    // BROKER paramAddr is blank
    // CLIENT paramter is cusip and BrokerAddre, paramAddr is broker address
    function getSecRate (string cusip, address paramAddr) returns (string rateList, uint[] loanAmt, uint[] collateralAmt) {
        string[] storage list;
        if (acctExists[msg.sender] == 2) list = brokerAcct[msg.sender].bySecurity[cusip].rateList;
        if (acctExists[msg.sender] == 3) list = clientAcct[msg.sender].bySecurity[cusip].byBroker[paramAddr].rateList;

        loanAmt = new uint[](list.length);
        collateralAmt = new uint[](list.length);

        for(uint i = 0; i < list.length; i++) {
            rateList = ConcatStrings.concatList(rateList, list[i]);
            (loanAmt[i], collateralAmt[i]) = getSecRateTotals(cusip, list[i], paramAddr);
        }
    }

    // // BROKER paramAddr is blank
    // // CLIENT paramAddr is broker address
    function getSecRateTotals (string cusip, string rate, address paramAddr) internal returns (uint loanAmt, uint collateralAmt) {
        CollateralDataStructs.RateMap storage rateDetails;
        if (acctExists[msg.sender] == 2) rateDetails =  brokerAcct[msg.sender].bySecurity[cusip].byRate[rate];
        if (acctExists[msg.sender] == 3) rateDetails =  clientAcct[msg.sender].bySecurity[cusip].byBroker[paramAddr].byRate[rate];
        return (rateDetails.loanAmt, rateDetails.collateralAmt);
    }

    // BROKER rate is Rate for Agent, paramAddr is blank
    // CLIENT rate is blank/"", paramAddr is broker address
    function getSecAgent(string cusip, string rate, address paramAddr) returns (string agentsList, address[] agentAddrs, uint[] loanAmt, uint[] collateralAmt) {
        address[] storage agentsListed;
        if (acctExists[msg.sender] == 2) agentsListed = brokerAcct[msg.sender].bySecurity[cusip].byRate[rate].agentList;
        else if (acctExists[msg.sender] == 3) {
            if (sha3(rate) != sha3('')) {
                agentsListed = clientAcct[msg.sender].bySecurity[cusip].byBroker[paramAddr].byRate[rate].agentList;
            } else {
                agentsListed = clientAcct[msg.sender].bySecurity[cusip].byBroker[paramAddr].agentList;
            }
        }

        loanAmt = new uint[](agentsListed.length);
        collateralAmt = new uint[](agentsListed.length);
        agentAddrs = new address[](agentsListed.length);
        string memory agentName;
        for(uint i = 0; i < agentsListed.length; i++) {
            agentAddrs[i] = agentsListed[i];
            (agentName, loanAmt[i], collateralAmt[i]) =  getSecAgentTotals(cusip, agentsListed[i], rate, paramAddr);
            agentsList = ConcatStrings.concatList(agentsList, agentName);
        }
    }

    // BROKER rate is Rate for Agent, paramAddr is blank
    // CLIENT rate is blank/"", paramAddr is broker address
    function getSecAgentTotals (string cusip, address agentAddr, string rate, address paramAddr) internal returns (string agentName, uint loanAmt, uint collateralAmt) {
        CollateralDataStructs.AgentMap storage agentDetails;
        if (acctExists[msg.sender] == 2) agentDetails = brokerAcct[msg.sender].bySecurity[cusip].byRate[rate].byAgent[agentAddr];
        else if (acctExists[msg.sender] == 3) agentDetails = clientAcct[msg.sender].bySecurity[cusip].byBroker[paramAddr].byAgent[agentAddr];
        return (agentAcct[agentAddr].acctName, agentDetails.loanAmt, agentDetails.collateralAmt);
    }

// Transaction History

    function getTransactionIds () returns (uint[] ids) {
        return (transactionMap[msg.sender]);
    }

    function getTransactionDetails (uint id) returns (address brokerAddr, address clientAddr, address agentAddr, string cusip, string rate, uint loanAmt, uint collateralAmt, uint dateTime) {
        CollateralDataStructs.Transaction storage t = allTransactions[id];
        require(msg.sender == t.brokerAddr || msg.sender == t.agentAddr || msg.sender == t.clientAddr); // Has to be member of trade to see details
        return (t.brokerAddr, t.clientAddr, t.agentAddr, t.cusip, t.rate, t.loanAmt, t.collateralAmt, t.dateTime);
    }

}