export type CafeData = {
  coffeeType: string;
  quantity: bigint;
  totalPrice: bigint;
  nonce: bigint;
  signature: string;
};

export type OrderCoffeeInputData = {
  clientAddress: `0x${string}`;
  coffeeType: string;
  quantity: bigint;
  totalPrice: bigint;
  nonce: bigint;
  signature: string;
  priorityFee?: bigint;
  noncePay: bigint;
  signaturePay: string;
};
