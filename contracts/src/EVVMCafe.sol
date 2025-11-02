// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {SignatureRecover} from "@evvm/testnet-contracts/library/SignatureRecover.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {StakingServiceHooks} from "@evvm/testnet-contracts/library/StakingServiceHooks.sol";

contract EVVMCafe is StakingServiceHooks {
    // ============================================================================
    // ERRORS
    // ============================================================================

    /// @notice Thrown when a provided signature is invalid or verification fails
    error InvalidSignature();

    /// @notice Thrown when attempting to reuse a nonce that has already been consumed
    error NonceAlreadyUsed();

    /// @notice Thrown when an unauthorized action is attempted
    error Unauthorized();

    // ============================================================================
    // STATE VARIABLES
    // ============================================================================

    /// @notice Address of the EVVM virtual blockchain contract for payment processing
    address evvmAddress;

    /// @notice Staking service contract address
    address stakingAddress;

    /// @notice Constant representing ETH in the EVVM virtual blockchain (address(0))
    address constant ETHER_ADDRESS = address(0);

    /// @notice Constant representing the principal token in EVVM virtual blockchain (address(1))
    address constant PRINCIPAL_TOKEN_ADDRESS = address(1);

    /// @notice Address of the coffee shop owner who can withdraw funds and rewards
    address ownerOfShop;

    /// @notice Mapping to track used nonces per client address to prevent replay attacks
    /// @dev First key: client address, Second key: nonce, Value: whether nonce is used
    mapping(address => mapping(uint256 => bool)) checkAsyncNonce;

    // ============================================================================
    // MODIFIERS
    // ============================================================================

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
    ) StakingServiceHooks(_stakingAddress) {
        evvmAddress = _evvmAddress;
        ownerOfShop = _ownerOfShop;
        stakingAddress = _stakingAddress;
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

        // Prevent replay attacks by checking if nonce has been used before
        if (checkAsyncNonce[clientAddress][nonce]) revert NonceAlreadyUsed();

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
        if (IEvvm(evvmAddress).isAddressStaker(address(this))) {
            // Transfer the priority fee to the fisher as immediate incentive
            IEvvm(evvmAddress).caPay(
                msg.sender,
                ETHER_ADDRESS,
                priorityFee_EVVM
            );

            // Transfer half of the reward (on principal tokens) to the fisher
            IEvvm(evvmAddress).caPay(
                msg.sender,
                PRINCIPAL_TOKEN_ADDRESS,
                IEvvm(evvmAddress).getRewardAmount() / 2
            );
        }

        // Mark nonce as used to prevent future reuse
        checkAsyncNonce[clientAddress][nonce] = true;
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
        Staking(stakingAddress).prepareServiceStaking(amountToStake);
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
        uint256 balance = IEvvm(evvmAddress).getBalance(
            address(this),
            PRINCIPAL_TOKEN_ADDRESS
        );

        // Transfer all accumulated reward tokens to the specified address
        IEvvm(evvmAddress).caPay(to, PRINCIPAL_TOKEN_ADDRESS, balance);
    }

    /**
     * @notice Withdraws accumulated ETH funds from coffee sales
     * @dev Only callable by the coffee shop owner
     *
     * @param to Address where the withdrawn ETH will be sent
     */
    function withdrawFunds(address to) external onlyOwner {
        // Get the current ETH balance held by the contract
        uint256 balance = IEvvm(evvmAddress).getBalance(
            address(this),
            ETHER_ADDRESS
        );

        // Transfer all accumulated ETH to the specified address
        IEvvm(evvmAddress).caPay(to, ETHER_ADDRESS, balance);
    }

    function isThisNonceUsed(
        address clientAddress,
        uint256 nonce
    ) external view returns (bool) {
        return checkAsyncNonce[clientAddress][nonce];
    }

    function getOwnerOfShop() external view returns (address) {
        return ownerOfShop;
    }

    function getPrincipalTokenAddress() external pure returns (address) {
        return PRINCIPAL_TOKEN_ADDRESS;
    }

    function getEtherAddress() external pure returns (address) {
        return ETHER_ADDRESS;
    }

    function getAmountOfPrincipalTokenInShop() external view returns (uint256) {
        return
            IEvvm(evvmAddress).getBalance(
                address(this),
                PRINCIPAL_TOKEN_ADDRESS
            );
    }

    function getEvvmAddress() external view returns (address) {
        return evvmAddress;
    }

    function getAmountOfEtherInShop() external view returns (uint256) {
        return IEvvm(evvmAddress).getBalance(address(this), ETHER_ADDRESS);
    }
}
