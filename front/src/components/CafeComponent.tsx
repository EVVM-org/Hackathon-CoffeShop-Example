"use client";
import styles from "./CafeComponent.module.css";
import Addresses from "@/constant/address.json";
import { formatEther } from "viem/utils";
import { generateRandomNumber } from "@/utils/mersenneTwister";
import { Ticket } from "./Ticket";
import { VisualExecution } from "./VisualExecution";
import { coffePriceMap } from "@/utils/coffeePriceMap";
import { CafeData } from "@/types/cafedata.type";
import { useEffect, useState } from "react";
import { CoffeeService } from "@/lib/services/coffee-service.evvm";
import { useEvvm } from "@/hooks/useEvvm";
import { IPayData, SignedAction } from "@evvm/evvm-js";
import { useAppKitAccount } from "@reown/appkit/react";

export const CafeComponent = () => {
  const { evvmService, signer } = useEvvm();
  const { isConnected } = useAppKitAccount();
  const [progressHistory, setProgressHistory] = useState<string>("begin");
  const [coffeeType, setCoffeeType] = useState<string>("Fisher Espresso");
  const [quantityCoffee, setQuantityCoffee] = useState<number>(1);
  const [priorityFlagOnEvvm, setPriorityFlagOnEvvm] = useState<string>("false");
  const [coffeeNonce, setCoffeeNonce] = useState<bigint>(
    BigInt(generateRandomNumber()),
  );
  const [evvmSyncNonce, setEvvmSyncNonce] = useState<bigint | null>(null);
  const [evvmAsyncNonce, setEvvmAsyncNonce] = useState<bigint>(
    BigInt(generateRandomNumber()),
  );
  // signed actions
  const [paySignedAction, setPaySignedAction] =
    useState<SignedAction<IPayData> | null>(null);
  const [orderCoffeeSignedAction, setOrderCoffeeSignedAction] =
    useState<SignedAction<CafeData> | null>(null);

  useEffect(() => {
    fetchSyncNonce();
  }, [evvmService]);

  const fetchSyncNonce = async () => {
    if (!evvmService) return;

    const nonce = await evvmService.getSyncNonce();
    setEvvmSyncNonce(nonce);
  };

  // Main function to create a cryptographic signature for the payment
  const makeSig = async () => {
    if (!signer) throw new Error("No signer when makeSig() called");
    if (!evvmService) throw new Error("No evvmService when makeSig() called");
    if (evvmSyncNonce == null)
      throw new Error("No evvmSyncNonce when makeSig() called");

    // instantiate custom coffee service
    const coffeeService = new CoffeeService(signer);

    const nonce =
      priorityFlagOnEvvm === "false" ? evvmSyncNonce : evvmAsyncNonce;

    const paySignedAction = await evvmService.pay({
      to: Addresses.CafeAddress,
      tokenAddress: "0x0000000000000000000000000000000000000000",
      amount: coffePriceMap[coffeeType] * BigInt(quantityCoffee),
      priorityFee: coffePriceMap[coffeeType] / BigInt(1000),
      nonce,
      priorityFlag: priorityFlagOnEvvm === "true",
      executor: Addresses.CafeAddress,
    });

    const orderCoffeeSignedAction = await coffeeService.orderCoffee({
      coffeeType,
      quantity: BigInt(quantityCoffee),
      totalPrice: coffePriceMap[coffeeType] * BigInt(quantityCoffee),
      nonce,
      evvmSignedAction: paySignedAction,
    });

    setPaySignedAction(paySignedAction);
    setOrderCoffeeSignedAction(orderCoffeeSignedAction);
    setProgressHistory("signed");
  };

  if (!isConnected) return null;

  return (
    <div>
      {progressHistory === "begin" && (
        <>
          <p>Select Coffee Type:</p>
          <select
            className={styles.cafeSelect}
            value={coffeeType}
            onChange={(e) => setCoffeeType(e.target.value)}
          >
            <option value="Fisher Espresso">Fisher Espresso</option>
            <option value="Virtual Cappuccino">Virtual Cappuccino</option>
            <option value="Decentralized Latte">Decentralized Latte</option>
            <option value="Nonce Mocha">Nonce Mocha</option>
          </select>

          <p>Quantity:</p>
          <select
            className={styles.cafeSelect}
            value={quantityCoffee}
            onChange={(e) => setQuantityCoffee(Number(e.target.value))}
          >
            <option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
            <option value="4">4</option>
            <option value="5">5</option>
          </select>

          <p>
            Total Price:{" "}
            {formatEther(coffePriceMap[coffeeType] * BigInt(quantityCoffee))}{" "}
            ETH
          </p>

          <button onClick={() => setProgressHistory("confirming")}>
            Confirm Order and Pay
          </button>
        </>
      )}

      {progressHistory === "confirming" && (
        <>
          <p>
            Price:{" "}
            {formatEther(coffePriceMap[coffeeType] * BigInt(quantityCoffee))}{" "}
            ETH
          </p>

          <div>
            Service nonce:{" "}
            <input
              type="number"
              id="nonceInput_Cafe"
              placeholder="Enter nonce"
              value={coffeeNonce.toString()}
              onChange={(e) => setCoffeeNonce(BigInt(e.target.value))}
            />
            <button
              onClick={() => setCoffeeNonce(BigInt(generateRandomNumber()))}
            >
              Generate Random Nonce
            </button>
          </div>

          <p>
            Priority fee for the transaction:{" "}
            {formatEther(coffePriceMap[coffeeType] / BigInt(1000))} ETH
          </p>

          <div>
            Using{" "}
            <select
              value={priorityFlagOnEvvm}
              onChange={(e) => setPriorityFlagOnEvvm(e.target.value)}
            >
              <option value="false">Sync nonces</option>
              <option value="true">Async nonces</option>
            </select>
            {priorityFlagOnEvvm === "false" ? (
              <div>
                {evvmSyncNonce != null ? (
                  <p>Current Sync Nonce: {evvmSyncNonce?.toString()}</p>
                ) : (
                  <p>Loading...</p>
                )}
              </div>
            ) : (
              <div>
                <input
                  type="number"
                  id="nonceAsyncInput_Pay"
                  placeholder="Enter nonce"
                  value={evvmAsyncNonce.toString()}
                  onChange={(e) => setEvvmAsyncNonce(BigInt(e.target.value))}
                />
                <button
                  onClick={() =>
                    setEvvmAsyncNonce(BigInt(generateRandomNumber()))
                  }
                >
                  Generate Random Nonce
                </button>
              </div>
            )}
          </div>
          <button onClick={makeSig}>Make Signature and Pay</button>
        </>
      )}

      {paySignedAction &&
        orderCoffeeSignedAction &&
        progressHistory === "signed" && (
          <>
            <Ticket
              orderCoffeeSignedAction={orderCoffeeSignedAction}
              paySignedAction={paySignedAction}
            />

            <button onClick={() => setProgressHistory("fishing")}>
              Send this to the fishing spot
            </button>
          </>
        )}

      {orderCoffeeSignedAction && progressHistory === "fishing" && (
        <div>
          <VisualExecution
            orderCoffeeSignedAction={orderCoffeeSignedAction.toJSON()}
          />
        </div>
      )}
    </div>
  );
};
