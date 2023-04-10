import { Migration } from "./migration";
import * as fs from 'fs';
import { SimpleKeystore } from "everscale-standalone-client/nodejs";
import {
  toNano,
  WalletTypes,
  getRandomNonce,
  Address,
  zeroAddress
} from 'locklift';

async function main() {

  const migration = new Migration();
  migration.reset();

  const keyPair = SimpleKeystore.generateKeyPair();
  console.log(`public: ${keyPair.publicKey}`);
  console.log(`secret: ${keyPair.secretKey}`);
  migration.storeKeyPair(keyPair, 'MintKeyPair');

  locklift.keystore.addKeyPair(keyPair);

  // ============ OWNER ACCOUNT ============
  const signer = await locklift.keystore.getSigner('0');
  const account = (
    await locklift.factory.accounts.addNewAccount({
      type: WalletTypes.EverWallet,
      value: toNano(5),
      publicKey: signer.publicKey,
    })
  ).account;

  const name = `Account1`;
  migration.store(account.address, 'wallet', name);
  console.log(`${name}: ${account.address}`);

  // ============ COLLECTION ============
  const jsonData = JSON.parse(fs.readFileSync("collection.json", 'utf8'));

  const Nft = await locklift.factory.getContractArtifacts("NftWithRoyalty");
  const MultiTokenWallet = await locklift.factory.getContractArtifacts("MultiTokenWalletWithRoyalty");
  const Index = await locklift.factory.getContractArtifacts("Index");
  const IndexBasis = await locklift.factory.getContractArtifacts("IndexBasis");
  const MultiTokenWalletPlatform = await locklift.factory.getContractArtifacts("MultiTokenWalletPlatform");

  const  collectionContractName = "MultiTokenCollectionWithRoyalty";
  const {contract: collection} = await locklift.factory.deployContract({
    contract: collectionContractName,
     //@ts-ignore
    constructorParams: {
      codeNft: Nft.code,
      codeToken: MultiTokenWallet.code,
      codeIndex: Index.code,
      codeIndexBasis: IndexBasis.code,
      ownerAddress: account.address,
      json: JSON.stringify(jsonData.collectionJson),
      remainingGasTo: account.address
    },
    //@ts-ignore
    initParams: {
      _deployer: zeroAddress,
      _nonce: getRandomNonce(),
      _platformCode: MultiTokenWalletPlatform.code
    },
    publicKey: keyPair.publicKey,
    value: toNano(4),
  });

  migration.store(collection.address, collectionContractName, collectionContractName);
  console.log(`Collection: ${collection.address}`);

  console.log('='.repeat(64));
  console.log(JSON.stringify(migration.migration_log));
  console.log('='.repeat(64));
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.log(e);
    process.exit(1);
  });
