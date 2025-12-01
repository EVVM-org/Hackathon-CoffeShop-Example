// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
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
     * @param _evvmAddress Address of the EVVM virtual blockchain contract for payment processing
     * @param _ownerOfShop Address that will have administrative privileges over the shop
     */
    constructor(
        address _evvmAddress,
        address _stakingAddress,
        address _ownerOfShop
    ) EvvmService(_evvmAddress, _stakingAddress) {
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
     * @param priorityFee_EVVM Fee paid for transaction priority in EVVM
     * @param nonce_EVVM Unique nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM Boolean flag indicating the type of nonce we are using
     *                          (true for async nonce, false for sync nonce)
     * @param signature_EVVM Signature authorizing the EVVM payment transaction
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
        validateServiceSignature(
            "orderCoffee",
            string.concat(
                coffeeType,
                ",",
                AdvancedStrings.uintToString(quantity),
                ",",
                AdvancedStrings.uintToString(totalPrice),
                ",",
                AdvancedStrings.uintToString(nonce)
            ),
            signature,
            clientAddress
        );

        // Prevent replay attacks by checking if nonce has been used before
        verifyAsyncServiceNonce(clientAddress, nonce);

        /**
         * Pay for the coffee using EVVM virtual blockchain's pay function
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
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        /**
         * FISHER INCENTIVE SYSTEM:
         * If this contract is registered as a staker in EVVM virtual blockchain, distribute rewards to the fisher.
         * This creates an economic incentive for fishers to process transactions.
         *
         * Rewards distributed:
         * 1. All priority fees paid by the client (priorityFee_EVVM)
         * 2. Half of the reward earned from this transaction
         *
         * Note: You could optionally restrict this to only staker fishers by adding:
         * IEvvm(evvmAddress).isAddressStaker(msg.sender) to the condition
         */
        if (evvm.isAddressStaker(address(this))) {
            // Transfer the priority fee to the fisher as immediate incentive
            makeCaPay(msg.sender, getEtherAddress(), priorityFee_EVVM);

            // Transfer half of the reward (on principal tokens) to the fisher
            makeCaPay(
                msg.sender,
                getPrincipalTokenAddress(),
                evvm.getRewardAmount() / 2
            );
        }

        // Mark nonce as used to prevent future reuse
        markAsyncServiceNonceAsUsed(clientAddress, nonce);
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
        uint256 balance = evvm.getBalance(
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
        uint256 balance = evvm.getBalance(address(this), getEtherAddress());

        // Transfer all accumulated ETH to the specified address
        makeCaPay(to, getEtherAddress(), balance);
    }

    function getOwnerOfShop() external view returns (address) {
        return ownerOfShop;
    }

    function getAmountOfPrincipalTokenInShop() external view returns (uint256) {
        return evvm.getBalance(address(this), getPrincipalTokenAddress());
    }

    function getAmountOfEtherInShop() external view returns (uint256) {
        return evvm.getBalance(address(this), getEtherAddress());
    }
}
