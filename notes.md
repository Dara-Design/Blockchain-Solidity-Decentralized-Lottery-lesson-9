You can always find your subscription IDs, balances, and consumers at vrf.chain.link.( https://vrf.chain.link/)

ENUMS IN SOLDITY: 
https://docs.soliditylang.org/en/latest/structure-of-a-contract.html#enum-types
https://docs.soliditylang.org/en/latest/types.html#enums

// In this example, require(msg.sender == minter); ensures that only the creator of the contract can call mint
 function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

