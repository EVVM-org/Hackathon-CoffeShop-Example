-include .env

.PHONY: all install compile anvil wizard help


# Network Arguments
ETH_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ETH_SEPOLIA) \
                            --account defaultKey \
                            --broadcast \
                            --verify \
                            --etherscan-api-key $(ETHERSCAN_API) \

# Main commands
deployContract: 
	@echo "Deploying testnet on Sepolia..."
	@forge clean
	@forge script script/EVVMCafe.s.sol:EVVMCafeScript $(ETH_SEPOLIA_TESTNET_ARGS) -vvvvvv
