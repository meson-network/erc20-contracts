// SPDX-License-Identifier: GPL v3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MSN_AIRDROP {
    address public msn_contract_address;

    //mining
    address public airdrop_signer;
    mapping(uint256 => uint256) private airdrop_sig_amount_map; // airdrop signature id => amount

    address public contract_owner;
    modifier onlyContractOwner() {
        require(msg.sender == contract_owner, "Only contractOwner");
        _;
    }

    constructor(address _msn_contract_addr) {
        msn_contract_address = _msn_contract_addr;
        contract_owner = msg.sender;
    }

    function check_airdrop_amount_from_signature(uint256 sig_id)
        public
        view
        returns (uint256)
    {
        return airdrop_sig_amount_map[sig_id];
    }

    function set_airdrop_signer(address _new_signer)
        external
        onlyContractOwner
    {
        airdrop_signer = _new_signer;
    }

    /**
     * Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
     * @dev Recover signer address from a message by using his signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address)
    {
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

    function check_airdrop_sig(
        uint256 sig_id,
        uint256 amount,
        bytes memory sig
    ) private view {
        bytes32 hash = keccak256(abi.encodePacked(sig_id, msg.sender, amount));
        address msg_signer = recover(hash, sig);
        require(msg_signer == airdrop_signer, "signature error");
    }

    function airdrop_claim(
        uint256 signature_id,
        uint256 amount,
        bytes memory signature
    ) public {
        require(amount > 0, "claim amount should be bigger then 0");

        require(airdrop_sig_amount_map[signature_id] == 0, "repeated claim");
        airdrop_sig_amount_map[signature_id] = amount;

        check_airdrop_sig(signature_id, amount, signature);

        //transfer
        bool result = IERC20(msn_contract_address).transfer(msg.sender, amount);
        require(result == true, "transfer error");
    }
}
