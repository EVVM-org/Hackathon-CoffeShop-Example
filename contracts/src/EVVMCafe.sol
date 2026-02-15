// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {CoreStructs} from "@evvm/testnet-contracts/interfaces/ICore.sol";
import {EvvmService} from "@evvm/testnet-contracts/library/EvvmService.sol";

contract EVVMCafe is EvvmService {
    // ============================================================================
    // ERRORS
    // ============================================================================

    /// @notice Thrown when an unauthorized action is attempted
    error Unauthorized();

    // ============================================================================
    // STATE VARIABLES
    // ============================================================================

    /// @notice Address of the coffee shop owner who can withdraw funds and rewards
    address ownerOfShop;

    // ============================================================================
    // MODIFIERS
    // ============================================================================

    /// @notice Modifier to restrict function access to only the coffee shop owner
    modifier onlyOwner() {
        if (msg.sender != ownerOfShop) revert Unauthorized();
        _;
    }

    // ============================================================================
    // CONSTRUCTOR
    // ============================================================================

    /**
     * @notice Initializes the coffee shop contract with EVVM integration
     * @param _coreAddress Address of the EVVM virtual blockchain contract for payment processing
     * @param _ownerOfShop Address that will have administrative privileges over the shop
     */
    constructor(
        address _coreAddress,
        address _stakingAddress,
        address _ownerOfShop
    ) EvvmService(_coreAddress, _stakingAddress) {
        ownerOfShop = _ownerOfShop;
    }

    // ============================================================================
    // EXTERNAL FUNCTIONS
    // ============================================================================

    /**
     * @notice Processes a coffee order with payment through EVVM
     *
     * @param clientAddress Address of the customer placing the order
     * @param coffeeType Type/name of coffee being ordered (e.g., "Espresso", "Latte")
     * @param quantity Number of coffee units being ordered
     * @param totalPrice Total price to be paid in ETH (in wei)
     * @param nonce Unique number to prevent replay attacks (must not be reused)
     * @param signature Client's signature authorizing the coffee order
     * @param priorityFeeEvvm Fee paid for transaction priority in EVVM
     * @param nonceEvvm Unique nonce for the EVVM payment transaction
     * @param priorityFlagEvvm Boolean flag indicating the type of nonce we are using
     *                          (true for async nonce, false for sync nonce)
     * @param signatureEvvm Signature authorizing the EVVM payment transaction
     *
     * @dev Signature format for client authorization:
     *      "<evvmID>,orderCoffee,<coffeeType>,<quantity>,<totalPrice>,<nonce>"
     *
     * @dev Reverts with InvalidSignature() if client signature verification fails
     * @dev Reverts with NonceAlreadyUsed() if nonce has been previously used
     */
    function orderCoffee(
        address clientAddress,
        string memory coffeeType,
        uint256 quantity,
        uint256 totalPrice,
        address originExecutor,
        uint256 nonce,
        bool isAsyncExec,
        bytes memory signature,
        uint256 priorityFeeEvvm,
        uint256 nonceEvvm,
        bool isAsyncExecEvvm,
        bytes memory signatureEvvm
    ) external {
        /**
         * Verify client's signature and evvm nonce for ordering coffee
         * The signed message format is:
         * "<evvmID>,<serviceAddress>,<hashPayload>,<originExecutor>,<nonce>,<isAsyncExec>"
         * Where:
         * · <evvmID> ------ is obtained from IEvvm(evvmAddress).getEvvmID()
         * · <serviceAddress> - is address(this) (the CoffeeShop contract)
         * · <hashPayload> --- is the keccak256 hash of the payload being signed
         *                     The payload is the encoding of the function 
         *                     name and parameters:
         *                    "orderCoffee,<coffeeType>,<quantity>,<totalPrice>"
         * · <originExecutor> -- is the address of the original executor 
         *                       (the fisher who will execute this transaction)
         * · <nonce> ---- is the number used to prevent replay attacks
         * · <isAsyncExec> -- indicates if the type of nonce execution is 
         *                     async (true) or sync (false)
         * If the signature is invalid because:
         * 1) It does not match the expected format
         * 2) It was not signed by the clientAddress
         * 3) some input data was tampered by the fisher or during transmission
         */
         core.validateAndConsumeNonce(
            user,
            keccak256(abi.encode(
                "orderCoffee",
                coffeeType,
                quantity,
                totalPrice
            )),
            originExecutor,
            nonce,
            isAsyncExec,
            signature
        );

        // Prevent replay attacks by checking if nonce has been used before

        /**
         * Pay for the coffee using EVVM virtual blockchain's pay function
         * The parameters are as follows:
         * · from ----------- clientAddress
         * · to_address ----- address(this) (the CoffeShop contract)
         * · to_identity ---- "" (not used in this case)
         * · token ---------- ETHER_ADDRESS (indicating payment in ETH)
         * · amount --------- totalPrice (the total price of the coffee)
         * · priorityFee ---- priorityFeeEvvm (fee for prioritizing the transaction)
         * · senderExecutor ------- address(this) (the CoffeShop contract will execute the payment)
         * · nonce ---------- nonceEvvm (unique number for this payment)
         * · isAsyncExec --- isAsyncExecEvvm (indicates if the payment is prioritized)
         * · signature ------ signatureEvvm (signature authorizing the payment)
         *
         * If the payment fails due to
         * 1) Insufficient balance
         * 2) Invalid amount
         * 3) Invalid async nonce
         * 4) Invalid signature
         * the EVVM virtual blockchain will revert the transaction accordingly.
         *
         * If the contract has some stake in the EVVM virtual blockchain receives
         * · All the priority fees paid by the client for this transaction
         * · 1 reward according to the EVVM's reward mechanism
         */
        requestPay(
            clientAddress,
            getEtherAddress(),
            totalPrice,
            priorityFeeEvvm,
            nonceEvvm,
            isAsyncExecEvvm,
            signatureEvvm
        );

        /**
         * FISHER INCENTIVE SYSTEM:
         * If this contract is registered as a staker in EVVM virtual blockchain, distribute rewards to the fisher.
         * This creates an economic incentive for fishers to process transactions.
         *
         * Rewards distributed:
         * 1. All priority fees paid by the client (priorityFeeEvvm)
         * 2. Half of the reward earned from this transaction
         *
         * Note: You could optionally restrict this to only staker fishers by adding:
         * IEvvm(evvmAddress).isAddressStaker(msg.sender) to the condition
         */
        if (core.isAddressStaker(address(this))) {
            // Transfer the priority fee to the fisher as immediate incentive
            makeCaPay(msg.sender, getEtherAddress(), priorityFeeEvvm);

            // Transfer half of the reward (on principal tokens) to the fisher
            makeCaPay(
                msg.sender,
                getPrincipalTokenAddress(),
                core.getRewardAmount() / 2
            );
        }
    }

    /**
     * @notice Stakes a specified amount of staking tokens for the coffee shop service
     * @dev Only callable by the coffee shop owner
     * @param amountToStake Number of staking tokens to stake
     */
    function stake(uint256 amountToStake) external onlyOwner {
        // a very easy way to make a service stake using the inherited function
        _makeStakeService(amountToStake);
        /*
        but if you want to do it step by step, you can use the following code:
        Staking(stakingAddress).2prepareServiceStaking(amountToStake);
        Evvm(evvmAddress).caPay(
            address(stakingAddress),
            0x0000000000000000000000000000000000000001,
            Staking(stakingAddress).priceOfStaking() * amountToStake
        );
        Staking(stakingAddress).confirmServiceStaking();
         */
    }

    /**
     * @notice Unstakes a specified amount of staking tokens for the coffee shop service
     * @dev Only callable by the coffee shop owner
     * @param amountToUnstake Number of staking tokens to unstake
     */
    function unstake(uint256 amountToUnstake) external onlyOwner {
        // this is using the inherited function to make a service unstake
        _makeUnstakeService(amountToUnstake);
        /*
        but if you don't want to use the inherited function, you can use the following code:
        
        Staking(stakingAddress).serviceUnstaking(amountToUnstake);
        
         */
    }

    /**
     * @notice Withdraws accumulated virtual blockchain reward tokens from the contract
     * @dev Only callable by the coffee shop owner
     *
     * @param to Address where the withdrawn reward tokens will be sent
     */
    function withdrawRewards(address to) external onlyOwner {
        // Get the current balance of principal tokens (EVVM virtual blockchain rewards)
        uint256 balance = core.getBalance(
            address(this),
            getPrincipalTokenAddress()
        );

        // Transfer all accumulated reward tokens to the specified address
        makeCaPay(to, getPrincipalTokenAddress(), balance);
    }

    /**
     * @notice Withdraws accumulated ETH funds from coffee sales
     * @dev Only callable by the coffee shop owner
     *
     * @param to Address where the withdrawn ETH will be sent
     */
    function withdrawFunds(address to) external onlyOwner {
        // Get the current ETH balance held by the contract
        uint256 balance = core.getBalance(address(this), getEtherAddress());

        // Transfer all accumulated ETH to the specified address
        makeCaPay(to, getEtherAddress(), balance);
    }

    function getOwnerOfShop() external view returns (address) {
        return ownerOfShop;
    }

    function getAmountOfPrincipalTokenInShop() external view returns (uint256) {
        return core.getBalance(address(this), getPrincipalTokenAddress());
    }

    function getAmountOfEtherInShop() external view returns (uint256) {
        return core.getBalance(address(this), getEtherAddress());
    }
}
