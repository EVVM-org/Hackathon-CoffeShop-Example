// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {SignatureRecover} from "@evvm/testnet-contracts/library/SignatureRecover.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CoffeShop {
    error InvalidSignature();
    error NonceAlreadyUsed();

    address evvmAddress;
    address constant ETHER_ADDRESS = address(0);
    address constant PRINCIPAL_TOKEN_ADDRESS = address(1);
    address ownerOfShop;

    mapping(address => mapping(uint256 => bool)) public checkAsyncNonce;

    constructor(address _evvmAddress, address _ownerOfShop) {
        evvmAddress = _evvmAddress;
        ownerOfShop = _ownerOfShop;
    }

    function orderCoffee(
        address clientAddress,
        string memory coffeeType,
        uint256 quantity,
        uint256 totalPrice,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external {
        /**
         * Verify client's signature for ordering coffee
         * The signed message format is:
         * "<evvmID>,orderCoffee,<coffeeType>,<quantity>,<totalPrice>,<nonce>"
         * Where:
         * · <evvmID> ------ is obtained from IEvvm(evvmAddress).getEvvmID()
         * · "orderCoffee" - is the name of the function being called
         * · <coffeeType> -- is the type of coffee ordered
         * · <quantity> ---- is the number of coffees ordered
         * · <totalPrice> -- is the total price to be paid in ETH
         * · <nonce> ------- is a unique number to prevent replay attacks
         * If the signature is invalid because:
         * 1) It does not match the expected format
         * 2) It was not signed by the clientAddress
         * 3) some input data was tampered by the fisher or during transmission
         */
        if (
            !SignatureRecover.signatureVerification(
                Strings.toString(IEvvm(evvmAddress).getEvvmID()),
                "orderCoffee",
                string.concat(
                    coffeeType,
                    ",",
                    Strings.toString(quantity),
                    ",",
                    Strings.toString(totalPrice),
                    ",",
                    Strings.toString(nonce)
                ),
                signature,
                clientAddress
            )
        ) revert InvalidSignature();

        /// Check if the nonce has already been used
        if (checkAsyncNonce[clientAddress][nonce]) revert NonceAlreadyUsed();

        /**
         * Pay for the coffee using EVVM's pay function
         * The parameters are as follows:
         * · from ----------- clientAddress
         * · to_address ----- address(this) (the CoffeShop contract)
         * · to_identity ---- "" (not used in this case)
         * · token ---------- ETHER_ADDRESS (indicating payment in ETH)
         * · amount --------- totalPrice (the total price of the coffee)
         * · priorityFee ---- priorityFee_EVVM (fee for prioritizing the transaction)
         * · nonce ---------- nonce_EVVM (unique number for this payment)
         * · priorityFlag --- priorityFlag_EVVM (indicates if the payment is prioritized)
         * · executor ------- address(this) (the CoffeShop contract will execute the payment)
         * · signature ------ signature_EVVM (signature authorizing the payment)
         *
         * If the payment fails due to
         * 1) Insufficient balance
         * 2) Invalid amount
         * 3) Invalid async nonce
         * 4) Invalid signature
         * the IEvvm contract will revert the transaction accordingly.
         *
         * If the contract has some stake in the EVVM receives
         * · All the priority fees paid by the client for this transaction
         * · 1 reward according to the EVVM's reward mechanism
         */
        IEvvm(evvmAddress).pay(
            clientAddress,
            address(this),
            "",
            ETHER_ADDRESS,
            totalPrice,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            address(this),
            signature_EVVM
        );

        /**
         * If the contract is a staker in the EVVM, give it the priority fees
         * and half of the reward earned from this transaction to the
         * fisher (msg.sender) as an incentive.
         *
         * Note: you can add
         * IEvvm(evvmAddress).isAddressStaker(msg.sender)
         * to check if the msg.sender is a staker so only stakers get the incentive.
         */
        if (IEvvm(evvmAddress).isAddressStaker(address(this))) {
            IEvvm(evvmAddress).caPay(
                address(this),
                ETHER_ADDRESS,
                priorityFee_EVVM
            );

            IEvvm(evvmAddress).caPay(
                address(this),
                PRINCIPAL_TOKEN_ADDRESS,
                IEvvm(evvmAddress).getRewardAmount() / 2
            );
        }
    }

    function withdrawRewards(address to) external {
        /**
         * Only the owner of the coffee shop can withdraw the rewards
         * accumulated in the contract.
         */
        if (msg.sender != ownerOfShop) revert InvalidSignature();

        /**
         * Withdraw all the rewards accumulated in the contract
         */
        uint256 balance = IEvvm(evvmAddress).getBalance(
            address(this),
            PRINCIPAL_TOKEN_ADDRESS
        );

        IEvvm(evvmAddress).caPay(to, PRINCIPAL_TOKEN_ADDRESS, balance);
    }

    function withdrawFunds(address to) external {
        /**
         * Only the owner of the coffee shop can withdraw the funds
         * accumulated in the contract.
         */
        if (msg.sender != ownerOfShop) revert InvalidSignature();

        /**
         * Withdraw all the funds accumulated in the contract
         */
        uint256 balance = IEvvm(evvmAddress).getBalance(
            address(this),
            ETHER_ADDRESS
        );

        IEvvm(evvmAddress).caPay(to, ETHER_ADDRESS, balance);
    }
}
