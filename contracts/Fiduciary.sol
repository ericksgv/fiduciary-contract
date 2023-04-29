// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


contract Fiduciary {

    address regulator;

    struct Beneficiary {
        uint percentage;
        uint balance;    
    }

    struct FiduciaryRelationship {
        address settlor;
        mapping (address => Beneficiary) beneficiariesP;
        uint trustBalance;
        uint auxiliarBalance;
        uint percentage;
        uint totalBeneficiaries;
        uint deadline;
    }

    mapping (address => FiduciaryRelationship) relations;

    mapping (address => uint) settlors;

    uint totalBalance;

    constructor () {
        regulator = msg.sender;
        totalBalance = 0;
    }


    function getFiduciaryBalance () public view returns (uint) {    
        assert(totalBalance==address(this).balance);
        return totalBalance;
    }


    // Function to validate if the sender is the regulator
    function isRegulator() public view returns (bool) {
        return msg.sender == regulator;
    }


    // Function to check if a beneficiary exists in the beneficiariesP mapping
    function containsBeneficiary(address _settlor, address _beneficiary) private view returns (bool) {
        return relations[_settlor].beneficiariesP[_beneficiary].percentage > 0;
    }


    // Function to verify if an address is the settlor of a fiduciary relationship
    function isSettlor() public view returns (bool) {
        address settlorAddress = relations[msg.sender].settlor;
        return settlorAddress == msg.sender;
    }

    // This function checks if a given deadline is valid
    function isValidDeadline(uint256 _deadline) private pure returns (bool) {
        if (_deadline == 0)
            return false;
        return true;
    }


    // Modifier to verify if the sender is the regulator
    modifier onlyRegulator() {
        require(isRegulator(), "Only regulator can call this function");
        _;
    }


    // Modificador para verificar si el remitente es un fideicomitente
    modifier onlySettlor() {
        require(isSettlor(), "Only a settlor can call this function");
        _;
    }


    // Function to create a new fiduciary relationship
    function createFiduciaryRelationship(address _settlor) public onlyRegulator{
        require(settlors[_settlor] == 0, "A settlor can only be settlor of one fiduciary relationship");

        FiduciaryRelationship storage relationship = relations[_settlor];

        relationship.settlor = _settlor;
        relationship.percentage = 0;
        relationship.deadline = 0;
        relationship.trustBalance = 0;
        relationship.auxiliarBalance = 0;

        settlors[_settlor] = 0;
    }


    // Function to add a deadline to a fiduciary relationship
    function addDeadline(uint _deadline) public onlySettlor{
        require(isValidDeadline(_deadline), "Deadline invalid");
        require(relations[msg.sender].deadline == 0, "A deadline already exists for this relationship");
        relations[msg.sender].deadline = block.timestamp + _deadline;
    }


    // Function to allow settlor to add beneficiaries with a percentage of benefit
    function addBeneficiary(address _beneficiary, uint _percentage) public onlySettlor{
        require(relations[msg.sender].deadline != 0, "Deadline has passed");
        require(!containsBeneficiary(msg.sender, _beneficiary), "Beneficiary already exists in the relationship");
        require(_percentage <= 100, "Beneficiary percentage cannot be greater than 100");
        require(relations[msg.sender].percentage + _percentage <= 100, "Total percentage of beneficiaries cannot exceed 100");

        // Add the beneficiary to the relationship
        relations[msg.sender].beneficiariesP[_beneficiary] = Beneficiary(_percentage, 0);
        relations[msg.sender].percentage = relations[msg.sender].percentage + _percentage;
        relations[msg.sender].totalBeneficiaries++;
    }


    // Function to allow settlor to transfer money to the fiduciary relationship
    function transferToRelationship() public payable onlySettlor{
        require(relations[msg.sender].deadline != 0 && block.timestamp <= relations[msg.sender].deadline, "Deadline has passed");
        
        // Transfer the money to the regulator's address
        //payable(regulator).transfer(msg.value);
        
        // Update the trust balance of the relationship with the transferred amount
        relations[msg.sender].trustBalance += msg.value;
        relations[msg.sender].auxiliarBalance += msg.value;
        
        // Update the total balance
        totalBalance += msg.value;
        assert(totalBalance==address(this).balance);
    }

    // Function for a beneficiary to withdraw their money from the fiduciary relationship
    function withdraw(address _settlor) public payable returns (bool) {
        address payable _beneficiary = payable (msg.sender);
        FiduciaryRelationship storage relationship = relations[_settlor];
         require(containsBeneficiary(_settlor, _beneficiary), "Beneficiary doesn't exists in the relationship");
         require(block.timestamp > relationship.deadline, "The deadline hasn't been passed");
         uint withdrawalAmount = (relationship.auxiliarBalance * relationship.beneficiariesP[_beneficiary].percentage) / 100;
        // uint withdrawalAmount = relationship.trustBalance;
        bool operationExecuted = _beneficiary.send(withdrawalAmount);
        require (operationExecuted, "The balance could not be withdrawn");
         relationship.beneficiariesP[_beneficiary].balance += withdrawalAmount;
        relationship.trustBalance -= withdrawalAmount;
        totalBalance -= withdrawalAmount;
        assert(totalBalance==address(this).balance);
        return true;
    }

    // Function that allows the regulator to liquidate a fiduciary relationship
    function liquidateFiduciaryRelationship(address _settlor) public payable onlyRegulator{
        require (relations[_settlor].settlor == _settlor, "Isn't a settlor");
        uint withdrawalAmount = relations[_settlor].trustBalance;
        totalBalance -= withdrawalAmount;
        bool operationExecuted = payable(_settlor).send(withdrawalAmount);
        require(operationExecuted, "Failed to transfer funds to settlor");
        relations[_settlor].trustBalance = 0;
        relations[_settlor].auxiliarBalance = 0;
        relations[_settlor].deadline = 0;
    }


    // Function to transfer remaining balance to the settlor after the deadline if there are no beneficiaries
    function transferRemainingBalance() public payable onlySettlor {
        FiduciaryRelationship storage relationship = relations[msg.sender];
        require(block.timestamp > relationship.deadline, "The deadline hasn't been passed");
        require(relationship.totalBeneficiaries == 0, "There are still beneficiaries in the relationship");

        payable(msg.sender).transfer(relationship.auxiliarBalance);

        relationship.trustBalance = 0;
        relationship.auxiliarBalance = 0;
        totalBalance -= relationship.auxiliarBalance;
    }

}