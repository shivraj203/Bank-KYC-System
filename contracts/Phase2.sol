// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract KYC{

    address admin;
    uint256 totalNumberOfBanks;


    // Struct to Store Customer Data
    struct Customer{
        string userName;        // UserName of Customer
        string customerData;    // Customer Data
        address bank;           // Unique Address of Bank
        bool kycStatus;         // If the number of upvotes/downvotes meet the required conditions, set kycStatus to true otherwise set it to false
        uint256 downVotes;         // Store Number of Down Votes
        uint256 upVotes;           // Store Number of Up Votes
    }


    // Struct to Store Bank Data
    struct Bank{
        string bankName;           // Bank Name
        address ethAddress;     // Unique ETH Address for Bank
        string regNumber;       // Registration Number of Bank
        uint256 complaintsReported; // Number of Complaints Reported
        uint256 kycCount;          // Number of KYC done by the Bank
        bool isAllowedToVote;   // Is Allowed to UpVote or DownVote
    }


    // Struct for KYC Request
    struct KYCRequest{
        string userName;        // UserName to Map KYC Request to Customer Data
        address bankAddress;    // Unique Address to Track the Bank
        string customerData;    // KYC Document Provided by Custo

    }

    // Default Constructor
    constructor() {
        admin = msg.sender;
        totalNumberOfBanks = 0;
    }


    // Mapping from Customer UserName to Customer struct 
    mapping(string => Customer) customers;

    // Mapping from Bank ETH Address to Bank struct
    mapping(address => Bank) banks;

    // Mapping to Hold List of KYC Request
    mapping(string => KYCRequest) kycRequests;

    // MAPPING TO HOLD LIST OF VOTES REGISTERED 
    mapping(address => mapping(string => bool)) hasVotedList ;      


    //***************************************** EVENT *****************************************
    event addCustomerEvent(string indexed _userName, string customerData, address bank);
    event modifyCustomerDataEvent(string indexed _userName, string customerData, address bank);
    event addBankEvent(address indexed _bankAddress, string bankName, string regNumber);
    event removeBankEvent(address indexed _bankAddress);
    event reportComplaintsEvent(address indexed _bankAddress, string bankName, uint256 complaintsReported);
    event modifyBankVotingEvent(address indexed _bankAddress, bool changedVotingStatus);
    event upVoteEvent(string indexed _userName, uint256 upVotes);
    event downVoteEvent(string indexed _userName, uint256 downVotes);
    event addRequestEvent(string indexed _userName, string _customerData, address bankAddress);
    event removeRequestEvent(string indexed _userName);

    //************************************* CHECK VALIDITY ************************************
    function validCustomer(string memory _userName) internal view returns(bool){
        return(customers[_userName].bank != address(0))? true : false;
    }

    function validBank(address _bankAddress) internal view returns(bool){
        return(banks[_bankAddress].ethAddress != address(0))? true : false;
    }

    function isAdmin() internal view returns(bool){
        return(msg.sender == admin) ? true : false;
    }

    function validVotingBank(address _bankAddress) internal view returns(bool){
        return(banks[_bankAddress].isAllowedToVote) ? true : false;
    }

    function validVotingHistory(string memory _userName)internal view returns(bool){
        return(hasVotedList[msg.sender][_userName] ? true : false);
    }

    function validRequest(string memory _userName)internal view returns(bool) {
        return(kycRequests[_userName].bankAddress == address(0) ? true : false);
    }

    // Function to Check KYC Status According to UpVotes and DownVotes
    function kycCheck(string memory _userName)internal view returns(bool){
        if(customers[_userName].upVotes > customers[_userName].downVotes){
            if(totalNumberOfBanks >= 6){
                return(customers[_userName].downVotes > (totalNumberOfBanks/3) ? false : true);
            }
            else {
                return true;
            }
        }
        else {
            return false;
        }
    }

    //************************************ BANK INTERFACE *************************************

    // Function Add KYC Request to KYC Requests
    function addRequest(string memory _userName, string memory _customerData) public {
        require(validBank(msg.sender), "Only Valid Bank can Add Request");
        require(validRequest(_userName), "KYC Request Already Done");

        kycRequests[_userName].userName = _userName;
        kycRequests[_userName].bankAddress = msg.sender;
        kycRequests[_userName].customerData = _customerData;
        banks[msg.sender].kycCount++;

        emit addRequestEvent(kycRequests[_userName].userName,kycRequests[_userName].customerData,kycRequests[_userName].bankAddress);
    }

     // Function Remove KYC Request to KYC Requests
    function removeRequest(string memory _userName) public {
        require(validBank(msg.sender), "Only Valid Bank can Add Request");
        require(!validRequest(_userName), "KYC Not Found");

        delete kycRequests[_userName];

        emit removeRequestEvent(_userName);
    }


    // Function to Add Customer Details
    function addCustomer(string memory _userName, string memory _customerData) public {
            // Check Bank is Valid Or Not
            require(validBank(msg.sender), "Valid Bank Can Add Customer Data");
            // Check that the customer does not already exist
            require(!validCustomer(_userName), "Customer Already Exist");
            // Check Valid KYC Request
            require(!validRequest(_userName), "KYC Request not found");

            // Create a new customer struct and populate its fields
            customers[_userName].userName = _userName;
            customers[_userName].customerData = _customerData;
            customers[_userName].bank = msg.sender;
            customers[_userName].upVotes = 0;
            customers[_userName].downVotes = 0;

            // Trigger the Event addCustomerEvent
            emit addCustomerEvent(customers[_userName].userName, customers[_userName].customerData, customers[_userName].bank);
    }


    // Function to View Customer Data
    function viewCustomer(string memory _userName) public view returns(string memory) {
            // Checks the User Exist or Not 
            require(validCustomer(_userName), "Customer does not Exist.");

            // Returns the Given User Data
            return customers[_userName].customerData;
    }


    // Function to Modify Existing Customer Data
    function modifyCustomerData(string memory _userName, string memory _customerData) public {
            // Checks the User Exist or Not
            require(validCustomer(_userName), "Customer does not Exist.");
            // Check Bank is Valid to Modify Data or Not
            require(validBank(msg.sender), "Only Valid Bank Can Modify Data");

            // Modify the Existing Customer Data
            customers[_userName].userName = _userName;
            customers[_userName].customerData = _customerData;
            customers[_userName].upVotes = 0;
            customers[_userName].downVotes = 0;

            // Trigger the Event modifyCustomerEvent
            emit modifyCustomerDataEvent(customers[_userName].userName, customers[_userName].customerData, customers[_userName].bank);
    }


    // Function to UpVote the Customer
    function upVote(string memory _userName) public {
        require(validBank(msg.sender), "Bank Does Not Exist");                  // Checks the Bank Exist or Not
        require(validVotingBank(msg.sender), "Only Valid Bank can Vote.");      // Check is Bank Allowed to Vote or Not
        require(validCustomer(_userName), "Customer does not Exist.");          // Checks the User Exist or Not
        require(!validVotingHistory(_userName), "You Have Already Voted");       // Check if Bank has Already Voted to Customer or Not

        customers[_userName].upVotes++;
        hasVotedList[msg.sender][_userName] = true;
        customers[_userName].kycStatus = kycCheck(_userName);

        emit upVoteEvent(_userName, customers[_userName].upVotes);
    }

    // Function to DownVote the Customer
    function downVote(string memory _userName) public {
       require(validBank(msg.sender), "Bank Does Not Exist");                  // Checks the Bank Exist or Not
        require(validVotingBank(msg.sender), "Only Valid Bank can Vote.");      // Check is Bank Allowed to Vote or Not
        require(validCustomer(_userName), "Customer does not Exist.");          // Checks the User Exist or Not
        require(!validVotingHistory(_userName), "You Have Already Voted");       // Check if Bank has Already Voted to Customer or Not

        customers[_userName].downVotes++;
        hasVotedList[msg.sender][_userName] = true;
        customers[_userName].kycStatus = kycCheck(_userName);

        emit downVoteEvent(_userName, customers[_userName].downVotes);
    }

    // Function to View Bank Details
    function viewBankDetails(address _bankAddress) public view returns(string memory){
        // Checks the Bank Exist or Not
        require(validBank(_bankAddress), "Bank Does Not Exist");

        // Returns Bank Details If Exist
        return banks[_bankAddress].bankName;
    }

    // Function to Get Number of Complaints Register Against the Bank
    function getComplaints(address _bankAddress) public view returns(uint256){
         // Checks the Bank Exist or Not
        require(validBank(_bankAddress), "Bank Does Not Exist");

        return(banks[_bankAddress].complaintsReported);
    }

    // Function to Report the Complaints Against Bank
    function reportComplaints(address _bankAddress, string memory _bankName) public {
         // Checks the Bank Exist or Not
        require(validBank(_bankAddress), "Bank Does Not Exist");
        // Checks if Bank is Valid to Vote or Not
        require(validBank(msg.sender), "Only Valid Bank can Register the Complaints.");

        banks[_bankAddress].complaintsReported++;
        banks[_bankAddress].isAllowedToVote = (banks[_bankAddress].complaintsReported > (totalNumberOfBanks/3)? false : true);

        // Trigger the Event reportComplaintsEvent
        emit reportComplaintsEvent(_bankAddress, _bankName,banks[_bankAddress].complaintsReported);

    }

    
    //************************************ ADMIN INTERFACE *************************************

    // Function to Add Bank Details
    function addBank(string memory _bankName, address _bankAddress, string memory _regNumber) public {
        // Check is Admin or Not
        require(isAdmin(), "Only Admin Access!");
        // Check Bank Exist or Not
        require(!validBank(_bankAddress), "Bank Already Exist");

        // Create a new customer struct and populate its fields
        banks[_bankAddress].bankName = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _regNumber;
        banks[_bankAddress].complaintsReported = 0;
        banks[_bankAddress].kycCount = 0;
        banks[_bankAddress].isAllowedToVote = true;
        totalNumberOfBanks++;

        // Trigger the Event addBankEvent
        emit addBankEvent(banks[_bankAddress].ethAddress, banks[_bankAddress].bankName, banks[_bankAddress].regNumber);
    }


    // Function to View The Bank Details
    function modifyBankVoting(address _bankAddress, bool changedVotingStatus)public {
        // Check is Admin or Not
        require(isAdmin(), "Only Admin Access!");
        // Check if Bank Exist or Not
        require(validBank(_bankAddress), "Bank Does Not Exist");

        banks[_bankAddress].isAllowedToVote = changedVotingStatus;

        // Trigger the Event modifyBankVotingEvent
        emit modifyBankVotingEvent(_bankAddress, changedVotingStatus);
    }


    // Function to Remove Bank for the List
    function removeBank(address _bankAddress) public{
        // Check is Admin or Not
        require(isAdmin(), "Only Admin Access!");
        // Check if Bank Exist or Not
        require(validBank(_bankAddress), "Bank Does Not Exist");

        delete banks[_bankAddress];
        totalNumberOfBanks--;

        // Trigger the Event removeBankEvent
        emit removeBankEvent(_bankAddress);    
    }

    // End of the KYC Smart Contract
}


