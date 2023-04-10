import { Migration } from "./migration";
import { toNano, WalletTypes, Contract, Address } from 'locklift';
import { FactorySource } from "../build/factorySource";

export declare type CollectionType = Contract<FactorySource["MultiTokenCollectionWithRoyalty"]>;

async function main() {

  const migration = new Migration();

  // ============ OWNER ACCOUNT ============
  const signer = await locklift.keystore.getSigner('0');
  const account = (
    await locklift.factory.accounts.addNewAccount({
      type: WalletTypes.EverWallet,
      value: toNano(0),
      publicKey: signer.publicKey,
    })
  ).account;

  console.log(`Account: ${account.address}`);

  // ============ COLLECTION ============
  const collectionContractName = 'Collection';
  const collection : CollectionType = migration.load(collectionContractName, collectionContractName);

  const newOwner = "";
  await collection.methods.transferOwnership({
        newOwner: new Address(newOwner)
      }
  ).send({
      from: account.address,
      amount: toNano(1)
  });

  const owner = (await collection.methods.owner().call()).value0;
  if (owner.toString() != newOwner) {
    console.log(`Error: owner not changed !`);
  } else {
    console.log(`Owner changed to: ${owner}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.log(e);
    process.exit(1);
  });
