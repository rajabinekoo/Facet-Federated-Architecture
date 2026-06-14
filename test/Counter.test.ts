import assert from "node:assert";
import { network } from "hardhat";
import { before, describe, it } from "node:test";
import {
  concatHex,
  keccak256,
  stringToHex,
  decodeEventLog,
  encodeFunctionData,
  decodeAbiParameters,
  decodeFunctionResult,
} from "viem";

import { FacetCut, FacetCutAction } from "../utils/facet.js";

const counterDomainId = keccak256(stringToHex("ffa.domain.counter"));

describe("Federal Core Smart Contract Test Cases", async function () {
  const { viem } = await network.create();
  const publicClient = await viem.getPublicClient();
  const accounts = await viem.getWalletClients();

  let Counter: Awaited<ReturnType<typeof viem.deployContract<"Counter">>>;
  let FederalCore: Awaited<
    ReturnType<typeof viem.deployContract<"FederalCore">>
  >;
  let FederalReceipts: Awaited<
    ReturnType<typeof viem.deployContract<"FederalReceipts">>
  >;
  let FederalRegistry: Awaited<
    ReturnType<typeof viem.deployContract<"FederalRegistry">>
  >;

  before(async () => {
    Counter = await viem.deployContract("Counter");
    FederalCore = await viem.deployContract("FederalCore", [
      accounts[0].account.address,
    ]);
    FederalReceipts = await viem.deployContract("FederalReceipts", [
      FederalCore.address,
    ]);
    FederalRegistry = await viem.deployContract("FederalRegistry", [
      accounts[0].account.address,
    ]);

    const setReceiptsHash = await FederalCore.write.changeReceipts([
      FederalReceipts.address,
    ]);
    await publicClient.waitForTransactionReceipt({ hash: setReceiptsHash });

    const counterFacetCut = new FacetCut(
      Counter.abi,
      Counter.address,
      FacetCutAction.Add,
    );

    const cutHash = await FederalRegistry.write.diamondCut([[counterFacetCut]]);
    await publicClient.waitForTransactionReceipt({ hash: cutHash });

    const addRegistryHash = await FederalCore.write.addRegistries([
      [counterDomainId],
      [FederalRegistry.address],
    ]);
    await publicClient.waitForTransactionReceipt({ hash: addRegistryHash });
  });

  it("Should increase count value and emit/decode federal receipts", async () => {
    const getCallData = concatHex([
      counterDomainId,
      encodeFunctionData({
        abi: Counter.abi,
        functionName: "get",
        args: [],
      }),
    ]);

    const result1 = await publicClient.call({
      to: FederalCore.address,
      data: getCallData,
    });

    const value1 = decodeFunctionResult({
      abi: Counter.abi,
      functionName: "get",
      data: result1.data!,
    });

    assert.equal(value1, 0n);

    const incrementData = concatHex([
      counterDomainId,
      encodeFunctionData({
        abi: Counter.abi,
        functionName: "increment",
        args: [],
      }),
    ]);

    const incrementHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: incrementData,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: incrementHash,
    });

    assert.ok(txReceipt);

    const receiptLog = txReceipt.logs.find(
      (log) =>
        log.address.toLowerCase() === FederalReceipts.address.toLowerCase(),
    );

    assert.ok(receiptLog);

    const parsedReceipt = decodeEventLog({
      abi: FederalReceipts.abi,
      topics: receiptLog!.topics,
      data: receiptLog!.data,
    });

    assert.equal(parsedReceipt.eventName, "ReceiptEmitted");

    const {
      domainId,
      eventType,
      data: innerLogData,
    } = parsedReceipt.args as {
      domainId: `0x${string}`;
      eventType: `0x${string}`;
      data: `0x${string}`;
    };

    assert.equal(domainId, counterDomainId);

    assert.equal(eventType, keccak256(stringToHex("CounterIncremented")));

    const CounterIncrementedAbi = Counter.abi.find(
      (item) => item.type === "event" && item.name === "CounterIncremented",
    )?.inputs;

    const [newValue] = decodeAbiParameters(
      CounterIncrementedAbi!,
      innerLogData,
    );

    assert.equal(newValue, 1n);

    const result2 = await publicClient.call({
      to: FederalCore.address,
      data: getCallData,
    });

    const value2 = decodeFunctionResult({
      abi: Counter.abi,
      functionName: "get",
      data: result2.data!,
    });

    assert.equal(value2, 1n);

    const mainValue = await Counter.read.get();

    assert.equal(mainValue, 0n);
  });
});
