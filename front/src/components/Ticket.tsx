import React from "react";
import { formatEther } from "viem/utils";
import styles from "./Ticket.module.css";
import { CafeData } from "@/types/cafedata.type";
import { IPayData, SignedAction } from "@evvm/evvm-js";

interface TicketProps {
  paySignedAction: SignedAction<IPayData>;
  orderCoffeeSignedAction: SignedAction<CafeData>;
}

export const Ticket: React.FC<TicketProps> = ({
  paySignedAction,
  orderCoffeeSignedAction,
}) => {
  return (
    <div className={styles.receiptContainer}>
      <div className={styles.receiptSection}>
        <h3 className={styles.receiptTitle}>EVVM Cafe Receipt</h3>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Coffee:</span>
          <span className={styles.receiptValue}>
            {orderCoffeeSignedAction.data.coffeeType}
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Qty:</span>
          <span className={styles.receiptValue}>
            {orderCoffeeSignedAction.data.quantity.toString()}
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Total:</span>
          <span className={`${styles.receiptValue} ${styles.receiptHighlight}`}>
            {formatEther(orderCoffeeSignedAction.data.totalPrice)} ETH
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Order #:</span>
          <span className={styles.receiptValue}>
            {orderCoffeeSignedAction.data.nonce.toString()}
          </span>
        </div>

        <div>
          <div className={styles.receiptLine}>
            <span className={styles.receiptLabel}>Order Sig:</span>
          </div>
          <div className={styles.receiptSignatureFull}>
            {orderCoffeeSignedAction.data.signature}
          </div>
        </div>
      </div>

      <div className={styles.receiptSection}>
        <h3 className={styles.receiptTitle}>Payment Details</h3>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>From:</span>
          <span className={styles.receiptSignature}>
            {paySignedAction.data.from.slice(0, 10)}...
            {paySignedAction.data.from.slice(-8)}
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>To:</span>
          <span className={styles.receiptSignature}>
            {paySignedAction.data.to_address?.slice(0, 10)}...
            {paySignedAction.data.to_address?.slice(-8)}
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Amount:</span>
          <span className={styles.receiptValue}>
            {formatEther(paySignedAction.data.amount)} ETH
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Priority Fee:</span>
          <span className={styles.receiptValue}>
            {paySignedAction.data.priorityFee &&
              formatEther(paySignedAction.data.priorityFee!)}{" "}
            ETH
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Nonce:</span>
          <span className={styles.receiptValue}>
            {paySignedAction.data.nonce.toString()}
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Priority:</span>
          <span className={styles.receiptValue}>
            {paySignedAction.data.isAsyncExec ? "Async" : "Sync"}
          </span>
        </div>

        <div className={styles.receiptLine}>
          <span className={styles.receiptLabel}>Executor:</span>
          <span className={styles.receiptSignature}>
            {paySignedAction.data.senderExecutor?.slice(0, 10)}...
            {paySignedAction.data.senderExecutor?.slice(-8)}
          </span>
        </div>

        <div>
          <div className={styles.receiptLine}>
            <span className={styles.receiptLabel}>Pay Sig:</span>
          </div>
          <div className={styles.receiptSignatureFull}>
            {paySignedAction.data.signature}
          </div>
        </div>
      </div>

      <div
        style={{
          textAlign: "center",
          fontSize: "10px",
          color: "#888",
          marginTop: "15px",
        }}
      >
        Thank you for visiting EVVM Cafe {"(˶ᵔ ᵕ ᵔ˶)"}
      </div>
    </div>
  );
};
