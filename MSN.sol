// SPDX-License-Identifier: GPL v3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MSN is ERC20 {
    address public contract_owner;

    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 inisupply
    ) ERC20(name, symbol) {
        contract_owner = msg.sender;
        _mint(msg.sender, inisupply * (10 ** uint256(decimals())));
    }

    address public contract_signer;

    function set_contract_signer(
        address _new_signer
    ) external onlyContractOwner {
        contract_signer = _new_signer;
    }

    /**
     * @dev Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(
        bytes32 hash,
        bytes memory sig
    ) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function check_mint_sig(
        uint256 sig_id,
        uint256 amount,
        bytes memory sig
    ) private view  {
        bytes32 hash = keccak256(abi.encodePacked(sig_id, msg.sender, amount));
        address msg_signer = recover(hash, sig);
        require(msg_signer == contract_signer, "signature error");
    }

    function miner_mint(
        uint256 signature_id,
        uint256 amount,
        bytes memory signature
    ) public {
        check_mint_sig(signature_id, amount, signature);
        //check daily reward pool of miners
        _mint(msg.sender, amount);
    }

    function airdrop_claim(
        uint256 signature_id,
        uint256 amount,
        bytes memory signature
    ) public {
        check_mint_sig(signature_id, amount, signature);
        //check daily airdrop limit
        //check total airdrop limit
        transfer(msg.sender, amount);
    }
}
