import { CafeComponent } from "@/components/CafeComponent";
import { ConnectButton } from "@/components/ConnectButton";

export default function Home() {
  return (
    <div className={"pages"}>
      <ConnectButton />
      <CafeComponent />
    </div>
  );
}

