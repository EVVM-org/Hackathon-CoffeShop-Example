import React from "react";
import styles from "./VisualExecution.module.css";
import { CafeData } from "@/types/cafedata.type";
import { SignedAction, execute } from "@evvm/evvm-js";
import { useEvvm } from "@/hooks/useEvvm";

interface VisualExecutionProps {
  orderCoffeeSignedAction: SignedAction<CafeData>;
}

export const VisualExecution: React.FC<VisualExecutionProps> = ({
  orderCoffeeSignedAction,
}) => {
  const { signer } = useEvvm();
  const jsonData = JSON.stringify(orderCoffeeSignedAction, null, 2);

  const executeTx = async () => {
    try {
      console.log("Executing...");
      const txHash = await execute(signer, orderCoffeeSignedAction);
      console.log("Success!");
      console.log({ txHash });
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <>
      <div className={styles.terminalContainer}>
        <div className={styles.terminalHeader}>
          <span className={styles.terminalTitle}>Order Data</span>
        </div>

        <pre className={styles.jsonContainer}>{jsonData}</pre>
      </div>
      <button onClick={executeTx}>Execute Transaction</button>
    </>
  );
};
