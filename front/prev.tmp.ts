// @ts-nocheck

// Get the current wallet connection
const walletData = await getAccountWithRetry(config);
const walletClient = await getWalletClient(config);
if (!walletData || !walletClient) {
  console.error("Wallet not connected");
  return;
}

const evvmSignatureBuilder = new (EVVMSignatureBuilder as any)(
  walletClient,
  walletData,
);
const genericSignatureBuilder = new (GenericSignatureBuilder as any)(
  walletClient,
  walletData,
);

// Helper function to get values from form inputs
const getValue = (id: string) =>
  (document.getElementById(id) as HTMLInputElement).value;

readEVVMId().then((evvmID) => {
  // Collect all form data into an object
  const coffeShopFormData = {
    coffeeType: coffeeType,
    quantity: BigInt(quantityCoffee),
    totalPrice: coffePriceMap[coffeeType] * BigInt(quantityCoffee),
    nonce: BigInt(getValue("nonceInput_Cafe")),
  };
  const formData = {
    evvmID: evvmID,
    to: address.CafeAddress as `0x${string}`,
    tokenAddress: "0x0000000000000000000000000000000000000000" as `0x${string}`, // Using native token (ETH)
    amount: coffePriceMap[coffeeType] * BigInt(quantityCoffee),
    priorityFee: coffePriceMap[coffeeType] / BigInt(1000),
    nonce:
      priorityFlagOnEvvm === "false"
        ? syncNonce?.toString() || "0"
        : getValue("nonceAsyncInput_Pay"),
    priorityFlag: priorityFlagOnEvvm === "true",
    executor: address.CafeAddress as `0x${string}`,
  };

  genericSignatureBuilder
    .signGenericMessage(
      formData.evvmID,
      "orderCoffee",
      coffeShopFormData.coffeeType +
        "," +
        coffeShopFormData.quantity.toString() +
        "," +
        coffeShopFormData.totalPrice.toString() +
        "," +
        coffeShopFormData.nonce.toString(),
    )
    .then((signature: any) => {
      setCoffeeReceipt({
        coffeeType: coffeShopFormData.coffeeType,
        quantity: coffeShopFormData.quantity,
        totalPrice: coffeShopFormData.totalPrice,
        nonce: coffeShopFormData.nonce,
        signature: signature,
      });
      evvmSignatureBuilder
        .signPay(
          formData.evvmID,
          formData.to,
          formData.tokenAddress as `0x${string}`,
          BigInt(formData.amount),
          BigInt(formData.priorityFee),
          BigInt(formData.nonce),
          formData.priorityFlag,
          formData.executor as `0x${string}`,
        )
        .then((paySignatire: any) => {
          setPayReceipt({
            from: walletData.address as `0x${string}`,
            to_address: formData.to,
            to_identity: "",
            token: formData.tokenAddress as `0x${string}`,
            amount: BigInt(formData.amount),
            priorityFee: BigInt(formData.priorityFee),
            nonce: BigInt(formData.nonce),
            priority: formData.priorityFlag,
            executor: formData.executor as `0x${string}`,
            signature: paySignatire,
          });
          // Prepare the order coffee data for contract call
          setOrderCoffeeData({
            clientAddress: walletData.address as `0x${string}`,
            coffeeType: coffeShopFormData.coffeeType,
            quantity: coffeShopFormData.quantity,
            totalPrice: coffeShopFormData.totalPrice,
            nonce: coffeShopFormData.nonce,
            signature: signature,
            priorityFee_EVVM: BigInt(formData.priorityFee),
            nonce_EVVM: BigInt(formData.nonce),
            priorityFlag_EVVM: formData.priorityFlag,
            signature_EVVM: paySignatire,
          });

          setProgressHistory("signed");
        });
    });
});
