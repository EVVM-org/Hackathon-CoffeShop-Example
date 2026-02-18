"use client";

import Addresses from "@/constant/address.json";
import { createSignerWithViem, Core, ISigner } from "@evvm/evvm-js";
import { useEffect, useState } from "react";
import { getWalletClient } from "wagmi/actions";
import { config } from "@/config";
import { useAppKitAccount } from "@reown/appkit/react";

export const useEvvm = () => {
  const { isConnected } = useAppKitAccount();
  const [signer, setSigner] = useState<ISigner | null>(null);
  const [evvmService, setEvvmService] = useState<Core | null>(null);

  useEffect(() => {
    setupSigner();
    setupEvvmService();
  }, [signer, isConnected]);

  const setupSigner = async () => {
    if (!isConnected) return;
    if (signer) return;

    const _walletClient = await getWalletClient(config);
    const _signer = await createSignerWithViem(_walletClient);

    setSigner(_signer);
  };

  const setupEvvmService = async () => {
    if (!signer) return;

    const _coreService = new Core({
      signer,
      address: Addresses.EVVMAddress as `0x${string}`,
      chainId: 11155111, // testnet
    });
    setEvvmService(_coreService);
  };

  return {
    signer,
    evvmService,
  };
};
