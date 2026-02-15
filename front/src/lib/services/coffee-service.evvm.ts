import {
  BaseService,
  IPayData,
  ISigner,
  SignedAction,
  SignMethod,
} from "@evvm/evvm-js";
import EvvmCafeABI from "@/constant/EVVMCafe.json";
import { OrderCoffeeInputData } from "@/types/cafedata.type";
import Addresses from "@/constant/address.json";

/**
 * Custom service for Coffee Shop use case
 */
export class CoffeeService extends BaseService {
  constructor(signer: ISigner) {
    super({
      signer,
      address: Addresses.CafeAddress,
      abi: EvvmCafeABI.abi,
      chainId: 11155111,
    });
  }

  @SignMethod
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
    const evvmId = await this.getEvvmID();
    const functionName = "orderCoffee";

    const inputs = `${coffeeType},${quantity.toString()},${totalPrice.toString()},${nonce.toString()}`;
    const message = `${evvmId},${functionName},${inputs}`;

    const signature = await this.signer.signMessage(message);

    return new SignedAction(this, evvmId, functionName, {
      clientAddress: this.signer.address,
      coffeeType,
      quantity,
      totalPrice,
      nonce,
      signature,
      priorityFeePay: evvmSignedAction.data.priorityFee,
      noncePay: evvmSignedAction.data.nonce,
      isAsyncExecPay: evvmSignedAction.data.isAsyncExec,
      signaturePay: evvmSignedAction.data.signature,
    });
  }
}
