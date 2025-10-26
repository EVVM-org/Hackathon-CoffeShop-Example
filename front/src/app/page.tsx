// import { cookieStorage, createStorage, http } from '@wagmi/core'
import { CafeComponent } from "@/components/CafeComponent";
import { ConnectButton } from "@/components/ConnectButton";
import Image from 'next/image';

export default function Home() {

  return (
    <div className={"pages"}>

      <ConnectButton />
      <CafeComponent />
    
    </div>
  );
}