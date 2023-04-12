// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Fiduciary {
    
    address regulator;
	
	struct Settlor {
		address addressS;
		uint amountMoney;
	}
	
	struct Beneficiary {
		address addressB; 
		uint benefits;
	}
	
	struct FiduciaryRelationship {
		address settlor;
		Beneficiary [] beneficiaries;
		mapping (address => uint) beneficiariesP;
		uint balance;
		uint deadline;
	}
	
	FiduciaryRelationship [] relations;
	
	constructor () {
		regulator = msg.sender;
	}
	
    function getRegulator () public view returns (address) {
        return regulator;
    }

    function createFiduciaryRelationship (address _settlor) public {
        require (regulator == msg.sender, "The regulator is the only who can create a fiduciary relationship");
        FiduciaryRelationship storage relation = relations.push();
        relation.settlor = _settlor;
        
    }

	
		
}