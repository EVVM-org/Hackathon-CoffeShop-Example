import { BaseService, IPayData, ISigner, SignedAction } from "@evvm/evvm-js";
import EvvmCafeABI from "@/constant/EVVMCafe.json";
import { OrderCoffeeInputData } from "@/types/cafedata.type";

/**
 * Custom service for Coffee Shop use case
 */
export class CoffeeService extends BaseService {
  constructor(signer: ISigner, address: string) {
    super(signer, address, EvvmCafeABI.abi);
  }

  async orderCoffee({
    coffeeType,
    quantity,
    totalPrice,
    nonce,
    evvmSignedAction,
  }: {
    coffeeType: string;
    quantity: bigint;
    totalPrice: bigint;
    nonce: bigint;
    evvmSignedAction: SignedAction<IPayData>;
  }): Promise<SignedAction<OrderCoffeeInputData>> {
    // const evvmId = await this.getEvvmID();
    const evvmId = evvmSignedAction.evvmId;
    const functionName = "orderCoffee";

    const inputs = `${coffeeType},${quantity.toString()},${totalPrice.toString()},${nonce.toString()}`;
    const message = `${evvmId},${functionName},${inputs}`;

    const signature = await this.signERC191Message(message);

    return new SignedAction(this, evvmId, functionName, {
      clientAddress: this.signer.address,
      coffeeType,
      quantity,
      totalPrice,
      nonce,
      signature,
      priorityFee_EVVM: evvmSignedAction.data.priorityFee,
      nonce_EVVM: evvmSignedAction.data.nonce,
      priorityFlag_EVVM: evvmSignedAction.data.priorityFlag,
      signature_EVVM: evvmSignedAction.data.signature,
    });
  }
}
