import assert from "node:assert";
import { network } from "hardhat";
import { writeFile } from "node:fs/promises";
import { after, before, describe, it } from "node:test";
import {
  concatHex,
  isAddress,
  keccak256,
  stringToHex,
  decodeEventLog,
  encodeFunctionData,
  decodeAbiParameters,
} from "viem";

import { nullAddress } from "../utils/address.js";
import { FacetCut, FacetCutAction } from "../utils/facet.js";

const assetWizardDomainId = keccak256(stringToHex("ffa.domain.AssetWizard"));
const marketplaceDomainId = keccak256(stringToHex("ffa.domain.Marketplace"));

const gasFileName = "gas-stats-functions.json";

describe("Game (FFA) Smart Contract Test Cases", async function () {
  const { viem } = await network.create();
  const publicClient = await viem.getPublicClient();
  const accounts = await viem.getWalletClients();

  let USDT: Awaited<ReturnType<typeof viem.deployContract<"MockUSDT">>>;
  let FederalCore: Awaited<
    ReturnType<typeof viem.deployContract<"FederalCore">>
  >;
  let FederalReceipts: Awaited<
    ReturnType<typeof viem.deployContract<"FederalReceipts">>
  >;
  let MarketplaceRegistry: Awaited<
    ReturnType<typeof viem.deployContract<"FederalRegistry">>
  >;
  let AssetWizardRegistry: Awaited<
    ReturnType<typeof viem.deployContract<"FederalRegistry">>
  >;
  let AssetFactory: Awaited<
    ReturnType<typeof viem.deployContract<"AssetFactory">>
  >;
  let AssetManagement: Awaited<
    ReturnType<typeof viem.deployContract<"AssetManagement">>
  >;
  let Market: Awaited<ReturnType<typeof viem.deployContract<"Market">>>;
  let Airdrop: Awaited<ReturnType<typeof viem.deployContract<"Airdrop">>>;
  let MarketStore: Awaited<
    ReturnType<typeof viem.deployContract<"MarketStore">>
  >;
  let AirdropStore: Awaited<
    ReturnType<typeof viem.deployContract<"AirdropStore">>
  >;
  let DeployedCollection: Awaited<
    ReturnType<typeof viem.deployContract<"AssetCollection">>
  >;

  const gasUsed: Record<string, string | number> = {};

  after(async () => {
    const finalGasUsed: Record<string, Record<string, string | number>> = {};
    for (const key in gasUsed) {
      if (!Object.hasOwn(gasUsed, key)) continue;
      const value = gasUsed[key];
      const [contract, functionName] = key.split(":");
      if (!finalGasUsed[contract]) finalGasUsed[contract] = {};
      finalGasUsed[contract][functionName] = value;
    }
    await writeFile(gasFileName, JSON.stringify(finalGasUsed), "utf8");
  });

  before(async () => {
    const owner = accounts[0].account.address;

    USDT = await viem.deployContract("MockUSDT");
    FederalCore = await viem.deployContract("FederalCore", [owner]);
    FederalReceipts = await viem.deployContract("FederalReceipts", [
      FederalCore.address,
    ]);
    AssetWizardRegistry = await viem.deployContract("FederalRegistry", [owner]);
    MarketplaceRegistry = await viem.deployContract("FederalRegistry", [owner]);

    const setReceiptsHash = await FederalCore.write.changeReceipts([
      FederalReceipts.address,
    ]);
    await publicClient.waitForTransactionReceipt({ hash: setReceiptsHash });

    const addRegistryHash = await FederalCore.write.addRegistries([
      [assetWizardDomainId, marketplaceDomainId],
      [AssetWizardRegistry.address, MarketplaceRegistry.address],
    ]);
    await publicClient.waitForTransactionReceipt({
      hash: addRegistryHash,
    });

    for (let i = 1; i < accounts.length; i++) {
      const mintTx = await USDT.write.mint([
        accounts[i].account.address,
        1000n * 10n ** 6n,
      ]);
      await publicClient.waitForTransactionReceipt({ hash: mintTx });
    }

    MarketStore = await viem.deployContract("MarketStore", [
      FederalCore.address,
    ]);
    AirdropStore = await viem.deployContract("AirdropStore", [
      FederalCore.address,
    ]);

    AssetFactory = await viem.deployContract("AssetFactory");
    AssetManagement = await viem.deployContract("AssetManagement");
    Airdrop = await viem.deployContract("Airdrop");
    Market = await viem.deployContract("Market");

    const assetFactoryFacetCut = new FacetCut(
      AssetFactory.abi,
      AssetFactory.address,
      FacetCutAction.Add,
    );
    const assetManagementFacetCut = new FacetCut(
      AssetManagement.abi,
      AssetManagement.address,
      FacetCutAction.Add,
    );
    const marketplaceFacetCut = new FacetCut(
      Market.abi,
      Market.address,
      FacetCutAction.Add,
    );
    const airdropFacetCut = new FacetCut(
      Airdrop.abi,
      Airdrop.address,
      FacetCutAction.Add,
    );

    const cutHash = await AssetWizardRegistry.write.diamondCut([
      [assetFactoryFacetCut, assetManagementFacetCut],
    ]);
    await publicClient.waitForTransactionReceipt({ hash: cutHash });

    const cutHash2 = await MarketplaceRegistry.write.diamondCut([
      [marketplaceFacetCut, airdropFacetCut],
    ]);
    await publicClient.waitForTransactionReceipt({ hash: cutHash2 });
  });

  it("should deploy a new collection", async () => {
    const createCollection = concatHex([
      assetWizardDomainId,
      encodeFunctionData({
        abi: AssetFactory.abi,
        functionName: "createCollection",
        args: ["TEST", "TST", ""],
      }),
    ]);

    const incrementHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: createCollection,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: incrementHash,
    });

    gasUsed["AssetFactory:createCollection"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
    assert.equal(txReceipt.logs.length, 1);

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

    assert.equal(domainId, assetWizardDomainId);

    assert.equal(eventType, keccak256(stringToHex("CollectionCreated")));

    const AssetWizardEvents = await viem.getContractAt(
      "contracts/game/FFA/AssetWizard/interfaces/IEvents.sol:IEvents",
      nullAddress,
    );

    const params = decodeAbiParameters(
      AssetWizardEvents.abi[0].inputs,
      innerLogData,
    );

    assert.equal(params.length, 4);
    assert.equal(isAddress(params[0]), true);
    assert.equal(params[1], "TEST");
    assert.equal(params[2], "TST");
    assert.equal(params[3], "");

    DeployedCollection = await viem.getContractAt(
      "AssetCollection",
      params[0] as `0x${string}`,
    );

    assert.ok(DeployedCollection);
  });

  it("should mint a new asset", async () => {
    const mintAsset = concatHex([
      assetWizardDomainId,
      encodeFunctionData({
        abi: AssetManagement.abi,
        functionName: "mint",
        args: [
          DeployedCollection.address,
          accounts[1].account.address,
          1n,
          15n,
          stringToHex("test"),
        ],
      }),
    ]);

    const mintHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: mintAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: mintHash,
    });

    gasUsed["AssetManagement:mint"] = txReceipt.gasUsed.toString();

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

    assert.equal(domainId, assetWizardDomainId);

    assert.equal(eventType, keccak256(stringToHex("TransferSingle")));

    const AssetWizardEvents = await viem.getContractAt("ERC1155", nullAddress);

    const params = decodeAbiParameters(
      AssetWizardEvents.abi[2].inputs,
      innerLogData,
    );

    assert.equal(
      params[0].toLowerCase(),
      accounts[0].account.address.toLowerCase(),
    );
    assert.equal(params[1], nullAddress);
    assert.equal(
      params[2].toLowerCase(),
      accounts[1].account.address.toLowerCase(),
    );
    assert(String(params[3]), "1");
    assert(String(params[4]), "15");
  });

  it("should batchMint a new asset", async () => {
    const mintAsset = concatHex([
      assetWizardDomainId,
      encodeFunctionData({
        abi: AssetManagement.abi,
        functionName: "batchMint",
        args: [
          DeployedCollection.address,
          accounts[1].account.address,
          [2n, 3n],
          [20n, 30n],
          stringToHex("test"),
        ],
      }),
    ]);

    const mintHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: mintAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: mintHash,
    });

    gasUsed["AssetManagement:batchMint"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should burn a new asset", async () => {
    const burnAsset = concatHex([
      assetWizardDomainId,
      encodeFunctionData({
        abi: AssetManagement.abi,
        functionName: "burn",
        args: [DeployedCollection.address, accounts[1].account.address, 1n, 5n],
      }),
    ]);

    const burnHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: burnAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: burnHash,
    });

    gasUsed["AssetManagement:burn"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should batchBurn a new asset", async () => {
    const burnAsset = concatHex([
      assetWizardDomainId,
      encodeFunctionData({
        abi: AssetManagement.abi,
        functionName: "batchBurn",
        args: [
          DeployedCollection.address,
          accounts[1].account.address,
          [2n, 3n],
          [5n, 10n],
        ],
      }),
    ]);

    const burnHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: burnAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: burnHash,
    });

    gasUsed["AssetManagement:batchBurn"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should init market", async () => {
    const treasury = accounts[5].account.address;

    const initMarket = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Market.abi,
        functionName: "init",
        args: [treasury, MarketStore.address, 0n],
      }),
    ]);

    const initMarketHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: initMarket,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: initMarketHash,
    });

    assert.ok(txReceipt);
  });

  it("should list a new asset in market", async () => {
    const listAsset = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Market.abi,
        functionName: "create",
        args: [
          DeployedCollection.address,
          USDT.address,
          1n,
          2n,
          4n * 10n ** 6n,
          50000n,
          BigInt(Date.now()),
        ],
      }),
    ]);

    const listHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: listAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: listHash,
    });

    gasUsed["Market:createListing"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should remove asset listing from market", async () => {
    const listAsset = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Market.abi,
        functionName: "remove",
        args: [DeployedCollection.address, 1n, 1n],
      }),
    ]);

    const listHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: listAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: listHash,
    });

    gasUsed["Market:removeListing"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should buyout listed asset by market", async () => {
    const now = BigInt(Math.floor(Date.now() / 1000));

    const startTime = now;
    const duration = 86400n; // 1 day

    const listAsset = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Market.abi,
        functionName: "create",
        args: [
          DeployedCollection.address,
          USDT.address,
          1n,
          2n,
          4n * 10n ** 6n,
          duration,
          startTime,
        ],
      }),
    ]);

    const listHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: listAsset,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: listHash,
    });

    assert.ok(txReceipt);

    const approveTx = await USDT.write.approve(
      [FederalCore.address, 4n * 10n ** 6n],
      { account: accounts[4].account },
    );
    await publicClient.waitForTransactionReceipt({ hash: approveTx });

    const buyoutAsset = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Market.abi,
        functionName: "buyout",
        args: [DeployedCollection.address, 1n, 2n],
      }),
    ]);

    const buyoutHash = await accounts[4].sendTransaction({
      to: FederalCore.address,
      data: buyoutAsset,
    });

    const txReceipt2 = await publicClient.waitForTransactionReceipt({
      hash: buyoutHash,
    });

    gasUsed["Market:buyout"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt2);
  });

  it("should init airdrop", async () => {
    const initAirdrop = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Airdrop.abi,
        functionName: "initAirdrop",
        args: [AirdropStore.address],
      }),
    ]);

    const initAirdropHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: initAirdrop,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: initAirdropHash,
    });

    assert.ok(txReceipt);
  });

  it("should make an airdrop", async () => {
    const now = BigInt(Math.floor(Date.now() / 1000));

    const startTime = now;
    const duration = 86400n; // 1 day

    const newAirdrop = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Airdrop.abi,
        functionName: "newAirdrop",
        args: [DeployedCollection.address, 4n, 5n, 3n, duration, startTime],
      }),
    ]);

    const newAirdropHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: newAirdrop,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: newAirdropHash,
    });

    gasUsed["Airdrop:newAirdrop"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should claim the airdrop", async () => {
    const claimAirdrop = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Airdrop.abi,
        functionName: "claim",
        args: [1n],
      }),
    ]);

    const claimAirdropHash = await accounts[3].sendTransaction({
      to: FederalCore.address,
      data: claimAirdrop,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: claimAirdropHash,
    });

    gasUsed["Airdrop:claim"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });

  it("should remove the airdrop", async () => {
    const removeAirdrop = concatHex([
      marketplaceDomainId,
      encodeFunctionData({
        abi: Airdrop.abi,
        functionName: "remove",
        args: [1n],
      }),
    ]);

    const removeAirdropHash = await accounts[0].sendTransaction({
      to: FederalCore.address,
      data: removeAirdrop,
    });

    const txReceipt = await publicClient.waitForTransactionReceipt({
      hash: removeAirdropHash,
    });

    gasUsed["Airdrop:remove"] = txReceipt.gasUsed.toString();

    assert.ok(txReceipt);
  });
});
