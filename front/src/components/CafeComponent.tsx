"use client";
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
import {
  Button,
  Container,
  Paper,
  Title,
  Text,
  Select,
  NumberInput,
  Stack,
  Group,
  Divider,
  Badge,
  Alert,
  ActionIcon,
  Loader,
} from "@mantine/core";
import { FaCoffee } from "react-icons/fa";
import { IoMdRefresh } from "react-icons/io";

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
      toAddress: Addresses.CafeAddress as `0x${string}`,
      tokenAddress: "0x0000000000000000000000000000000000000000",
      amount: coffePriceMap[coffeeType] * BigInt(quantityCoffee),
      priorityFee: coffePriceMap[coffeeType] / BigInt(1000),
      nonce,
      isAsyncExec: priorityFlagOnEvvm === "true",
      senderExecutor: Addresses.CafeAddress as `0x${string}`,
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
    <Container size="md" py="xl">
      {progressHistory === "begin" && (
        <Paper shadow="md" radius="lg" p="xl" withBorder>
          <Stack gap="lg">
            <Group gap="xs">
              <FaCoffee size={32} />
              <Title order={2}>EVVM Café</Title>
            </Group>
            
            <Divider />

            <Select
              label="Select Coffee Type"
              placeholder="Choose your coffee"
              value={coffeeType}
              onChange={(value) => setCoffeeType(value || "Fisher Espresso")}
              data={[
                { value: "Fisher Espresso", label: "☕ Fisher Espresso" },
                { value: "Virtual Cappuccino", label: "☕ Virtual Cappuccino" },
                { value: "Decentralized Latte", label: "☕ Decentralized Latte" },
                { value: "Nonce Mocha", label: "☕ Nonce Mocha" },
              ]}
              size="md"
              allowDeselect={false}
            />

            <NumberInput
              label="Quantity"
              placeholder="Enter quantity"
              value={quantityCoffee}
              onChange={(value) => setQuantityCoffee(Number(value))}
              min={1}
              max={10}
              size="md"
              allowDecimal={false}
              allowNegative={false}
            />

            <Divider />

            <Group justify="space-between" align="center">
              <Text size="lg" fw={500}>Total Price:</Text>
              <Badge size="xl" variant="gradient" gradient={{ from: 'orange', to: 'red' }}>
                {formatEther(coffePriceMap[coffeeType] * BigInt(quantityCoffee))} ETH
              </Badge>
            </Group>

            <Button 
              onClick={() => setProgressHistory("confirming")}
              size="lg"
              fullWidth
              leftSection={<FaCoffee size={20} />}
            >
              Confirm Order and Pay
            </Button>
          </Stack>
        </Paper>
      )}

      {progressHistory === "confirming" && (
        <Paper shadow="md" radius="lg" p="xl" withBorder>
          <Stack gap="lg">
            <Group gap="xs">
              <FaCoffee size={32} />
              <Title order={2}>Confirm Order</Title>
            </Group>

            <Divider />

            <Alert variant="light" color="blue" title="Order Summary">
              <Text size="sm">
                {coffeeType} × {quantityCoffee}
              </Text>
              <Text size="lg" fw={700} mt="xs">
                Total: {formatEther(coffePriceMap[coffeeType] * BigInt(quantityCoffee))} ETH
              </Text>
              <Text size="xs" c="dimmed" mt="xs">
                Priority fee: {formatEther(coffePriceMap[coffeeType] / BigInt(1000))} ETH
              </Text>
            </Alert>

            <Stack gap="md">
              <Group gap="xs" align="flex-end">
                <NumberInput
                  label="Service Nonce"
                  placeholder="Enter nonce"
                  value={coffeeNonce.toString()}
                  onChange={(value) => setCoffeeNonce(BigInt(value || 0))}
                  hideControls
                  flex={1}
                />
                <ActionIcon 
                  size="lg" 
                  variant="filled"
                  onClick={() => setCoffeeNonce(BigInt(generateRandomNumber()))}
                >
                  <IoMdRefresh size={18} />
                </ActionIcon>
              </Group>

              <Select
                label="Execution Mode"
                value={priorityFlagOnEvvm}
                onChange={(value) => setPriorityFlagOnEvvm(value || "false")}
                data={[
                  { value: "false", label: "Sync Nonces" },
                  { value: "true", label: "Async Nonces" },
                ]}
                allowDeselect={false}
              />

              {priorityFlagOnEvvm === "false" ? (
                <Alert variant="light" color="cyan">
                  {evvmSyncNonce != null ? (
                    <Group gap="xs" align="center">
                      <Text size="sm" component="span">
                        Current Sync Nonce:
                      </Text>
                      <Badge>{evvmSyncNonce.toString()}</Badge>
                    </Group>
                  ) : (
                    <Group gap="xs">
                      <Loader size="xs" />
                      <Text size="sm">Loading nonce...</Text>
                    </Group>
                  )}
                </Alert>
              ) : (
                <Group gap="xs" align="flex-end">
                  <NumberInput
                    label="Async Nonce"
                    placeholder="Enter nonce"
                    value={evvmAsyncNonce.toString()}
                    onChange={(value) => setEvvmAsyncNonce(BigInt(value || 0))}
                    hideControls
                    flex={1}
                  />
                  <ActionIcon 
                    size="lg" 
                    variant="filled"
                    onClick={() => setEvvmAsyncNonce(BigInt(generateRandomNumber()))}
                  >
                    <IoMdRefresh size={18} />
                  </ActionIcon>
                </Group>
              )}
            </Stack>

            <Divider />

            <Button 
              onClick={makeSig}
              size="lg"
              fullWidth
            >
              Sign and Pay
            </Button>
          </Stack>
        </Paper>
      )}

      {paySignedAction &&
        orderCoffeeSignedAction &&
        progressHistory === "signed" && (
          <Stack gap="lg">
            <Ticket
              orderCoffeeSignedAction={orderCoffeeSignedAction}
              paySignedAction={paySignedAction}
            />

            <Button 
              onClick={() => setProgressHistory("fishing")}
              size="lg"
              fullWidth
            >
              Send this to the fishing spot
            </Button>
          </Stack>
        )}

      {orderCoffeeSignedAction && progressHistory === "fishing" && (
        <Paper shadow="md" radius="lg" p="xl" withBorder>
          <VisualExecution
            orderCoffeeSignedAction={orderCoffeeSignedAction.toJSON()}
          />
        </Paper>
      )}
    </Container>
  );
};
