pragma solidity ^0.4.15;

contract Remittance {
    uint constant SEVEN_DAYS_IN_BLOCKS = 7 days / 15;

    struct RemittanceStruct {
        address owner;
        uint owed;
        uint blockDeadline;
    }   

    event LogRemittanceCreated(address recipient, uint value, uint deadline);
    event LogRemittanceWithdrawn(address recipient, uint value);
    event LogRemittanceCancelled(address recipient, uint value);

    mapping (bytes32 => RemittanceStruct) private remittances;
    
    function createRemittance(address recipient, bytes32 keccak256HashedPassword, uint blocksToDeadline) 
        payable
        returns (bool success)
        {
        // the message must have value
        require(msg.value > 0);

        // limit the deadline to be no greater than 7 days worth of blocks
        require(blocksToDeadline < SEVEN_DAYS_IN_BLOCKS);

        bytes32 key = keccak256(recipient, keccak256HashedPassword);

        // there must be no value stored for that recipient already maximum 1 remittance per address/password combination
        require(remittances[key].owed == 0);

        // create the struct representing the remittance
        remittances[key] = RemittanceStruct({
            blockDeadline: block.number + blocksToDeadline,
            owed: msg.value,
            owner: msg.sender
        });

        LogRemittanceCreated(recipient, msg.value, block.number + blocksToDeadline);

        return true;    
    }

    function withdrawRemittance(address recipient, string password) returns (bool success) {
        bytes32 key = keccak256(recipient, keccak256(password));
        RemittanceStruct memory forSender = remittances[key];

        // must have something to withdraw
        require(forSender.owed > 0);

        // must not be past block deadline
        require(block.number <= forSender.blockDeadline);

        uint owed = forSender.owed;
        remittances[key].owed = 0;
        
        recipient.transfer(owed);

        LogRemittanceWithdrawn(recipient, owed);

        return true;
    }

    function withdrawRemittance(string password) returns (bool success) {
        return withdrawRemittance(msg.sender, password);
    }

    function cancelRemittance(address recipient, string password) returns (bool success) {
        bytes32 key = keccak256(recipient, keccak256(password));
        RemittanceStruct memory remittance = remittances[key];

        // there must be a remittance in place
        require(remittance.owed > 0);
        
        // the owner must be the one cancelling the remittance
        require(remittance.owner == msg.sender);

        // the deadline must have passed
        require(remittance.blockDeadline > block.number);

        uint refund = remittances[key].owed;
        remittances[key].owed = 0;
        msg.sender.transfer(refund);

        LogRemittanceCancelled(recipient, refund);

        return true;
    }

}
