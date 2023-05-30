import { Address, Contract, getRandomNonce, toNano, zeroAddress } from "locklift";
import { Account } from "everscale-standalone-client/nodejs";
import { Contracts } from "./contracts";
import { MultiTokenWalletContract, MultiTokenWalletWithRoyaltyContract, MultiTokens } from "./multiTokens";
import { NftContract, NftWithRoyaltyContract, Nfts } from "./nfts";
import { FactorySource } from "build/factorySource";
import { expect } from "chai";

export declare type MultiTokenCollectionContract = Contract<FactorySource['MultiTokenCollection']>;
export declare type MultiTokenCollectionWithRoyaltyContract = Contract<FactorySource['MultiTokenCollectionWithRoyalty']>;
export declare type AnyMultiTokenCollectionContract = MultiTokenCollectionContract | MultiTokenCollectionWithRoyaltyContract;

const COLLECTION_METADATA = JSON.stringify({
    title: 'Test Collection'
});
const TOKEN_METADATA =  JSON.stringify({
    type: "Basic NFT",
    name: "Charging Bull",
    description: "Charging Bull from New York",
    preview: {
        source: "https://upload.wikimedia.org/wikipedia/en/c/c9/Charging_Bull_statue.jpg",
        mimetype: "image/jpeg"
    },
    files: [{
            source: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0b/Bowling_Green_NYC_Feb_2020_13.jpg/1920px-Bowling_Green_NYC_Feb_2020_13.jpg",
            mimetype: "image/jpeg"
    }],
    external_url: "https://en.wikipedia.org/wiki/Charging_Bull"
});
const DEFAULT_ROYALTY = 100_000;
const DEFAULT_ROYALTY_ADDRESS = new Address('0:ece57bcc6c530283becbbd8a3b24d3c5987cdddc3c8b7b33be6e4a6312490415');

export class Collections {
    static async deploy(ownerAddress: Address, publickey: string): Promise<MultiTokenCollectionContract> {

        const Nft = locklift.factory.getContractArtifacts("Nft");
        const MultiTokenWallet = locklift.factory.getContractArtifacts("MultiTokenWallet");
        const Index = locklift.factory.getContractArtifacts("Index");
        const IndexBasis = locklift.factory.getContractArtifacts("IndexBasis");
        const MultiTokenWalletPlatform = locklift.factory.getContractArtifacts("MultiTokenWalletPlatform");
    
        const {contract: collection} = await locklift.factory.deployContract({
            contract: "MultiTokenCollection",
            //@ts-ignore
            constructorParams: {
                codeNft: Nft.code,
                codeToken: MultiTokenWallet.code,
                codeIndex: Index.code,
                codeIndexBasis: IndexBasis.code,
                ownerAddress,
                json: COLLECTION_METADATA,
                remainingGasTo: ownerAddress
            },
            //@ts-ignore
            initParams: {
                _deployer: zeroAddress,
                _nonce: getRandomNonce(),
                _platformCode: MultiTokenWalletPlatform.code
            },
            publicKey: publickey,
            value: toNano(4),
        });
    
        await Collections.checkJson(collection, COLLECTION_METADATA);
        await Collections.checkTotalSupply(collection, 0);
        await Collections.checkOwner(collection, ownerAddress);
        await Contracts.checkContractBalance(collection.address, 500_000_000);
    
        return collection;
    }
    
    static async deployWithRoyalty(ownerAddress: Address, publickey: string): Promise<MultiTokenCollectionWithRoyaltyContract> {
    
        const Nft = locklift.factory.getContractArtifacts("NftWithRoyalty");
        const MultiTokenWallet = locklift.factory.getContractArtifacts("MultiTokenWalletWithRoyalty");
        const Index = locklift.factory.getContractArtifacts("Index");
        const IndexBasis = locklift.factory.getContractArtifacts("IndexBasis");
        const MultiTokenWalletPlatform = locklift.factory.getContractArtifacts("MultiTokenWalletPlatform");
    
        const {contract: collection} = await locklift.factory.deployContract({
            contract: "MultiTokenCollectionWithRoyalty",
            //@ts-ignore
            constructorParams: {
                codeNft: Nft.code,
                codeToken: MultiTokenWallet.code,
                codeIndex: Index.code,
                codeIndexBasis: IndexBasis.code,
                ownerAddress,
                json: COLLECTION_METADATA,
                remainingGasTo: ownerAddress
            },
            //@ts-ignore
            initParams: {
                _deployer: zeroAddress,
                _nonce: getRandomNonce(),
                _platformCode: MultiTokenWalletPlatform.code
            },
            publicKey: publickey,
            value: toNano(4),
        });
    
        await Collections.checkJson(collection, COLLECTION_METADATA);
        await Collections.checkTotalSupply(collection, 0);
        await Collections.checkOwner(collection, ownerAddress);
        await Contracts.checkContractBalance(collection.address, 500_000_000);
    
        return collection;
    }

    static attachDeployed(address: Address): MultiTokenCollectionContract {
        return locklift.factory.getDeployedContract(
            'MultiTokenCollection',
            address
        );
    }

    static attachDeployedWithRoyalty(address: Address): MultiTokenCollectionWithRoyaltyContract {
        return locklift.factory.getDeployedContract(
            'MultiTokenCollectionWithRoyalty',
            address
        );
    }

    static async getJson(contract: AnyMultiTokenCollectionContract): Promise<string> {
        return (await contract.methods.getJson({answerId: 0}).call()).json;
    }

    static async getTotalSupply(contract: AnyMultiTokenCollectionContract): Promise<number> {
        return Number((await contract.methods.totalSupply({answerId: 0}).call()).count);
    }

    static async getTotalMultiTokenSupply(contract: AnyMultiTokenCollectionContract, id: string): Promise<number> {
        let nftAddr = await Collections.nftAddress(contract, id)
        let nft = Nfts.attachDeployed(nftAddr)

        return Number((await nft.methods.multiTokenSupply({answerId: 0}).call()).count);
    }

    static async getOwner(contract: AnyMultiTokenCollectionContract): Promise<Address> {
        return (await contract.methods.owner().call()).value0;
    }

    static async checkJson(contract: AnyMultiTokenCollectionContract, expected: string) {
        const actual = await Collections.getJson(contract);
        expect(actual).to.be.eq(expected, 'Wrong collection JSON');
    }

    static async checkTotalSupply(contract: AnyMultiTokenCollectionContract, expected: number) {
        const actual = await Collections.getTotalSupply(contract);
        expect(actual).to.be.eq(expected, 'Wrong collection total supply');
    }

    static async checkTotalMultiTokenSupply(contract: AnyMultiTokenCollectionContract, id: string, expected: number) {
        const actual = await Collections.getTotalMultiTokenSupply(contract, id);
        expect(actual).to.be.eq(expected, 'Wrong collection multi token total supply');
    }

    static async checkOwner(contract: AnyMultiTokenCollectionContract, expected: Address) {
        const actual = await Collections.getOwner(contract);
        expect(actual.toString()).to.be.eq(expected.toString(), 'Wrong collection owner');
    }

    static async nftAddress(contract: AnyMultiTokenCollectionContract, id: string): Promise<Address> {
        return (await contract.methods.nftAddress({
            answerId: 0,
            id,
        }).call()).nft;
    }

    static async multiTokenWalletAddress(contract: AnyMultiTokenCollectionContract, id: string, owner: Address): Promise<Address> {
        return (await contract.methods.multiTokenWalletAddress({
            answerId: 0,
            id,
            owner
        }).call()).token;
    }

    static async mintNFT(
        collection: MultiTokenCollectionContract,
        owner: Account
    ): Promise<{
        nft: NftContract;
        id: string;
    }> {
        const { traceTree } = await locklift.tracing.trace(collection.methods.mintNft({
                answerId: 0,
                nftOwner: owner.address,
                json: TOKEN_METADATA,
                remainingGasTo: owner.address
            }
        ).send({
            from: owner.address,
            amount: toNano(2)
        }));
    
        const { id } = Contracts.getFirstEvent(traceTree, collection, 'NftCreated');
        const nftAddress = await Collections.nftAddress(collection, id);
    
        const nft = Nfts.attachDeployed(nftAddress);
    
        await Nfts.checkInfo(nft, {
            collection: collection.address,
            id,
            owner: owner.address,
            manager: owner.address
        });
        await Nfts.checkJson(nft, TOKEN_METADATA);
    
        return { nft, id };
    }
    
    static async mintNFTWithRoyalty(
        collection: MultiTokenCollectionWithRoyaltyContract,
        owner: Account,
        royaltyInfo: {
            royalty: number;
            royaltyAddress: Address;
        } = {
            royalty: DEFAULT_ROYALTY,
            royaltyAddress: DEFAULT_ROYALTY_ADDRESS
        }
    ): Promise<{
        nft: NftWithRoyaltyContract;
        id: string;
    }> {
        const { traceTree } = await locklift.tracing.trace(collection.methods.mintNft({
                answerId: 0,
                nftOwner: owner.address,
                json: TOKEN_METADATA,
                royalty: royaltyInfo.royalty,
                royaltyAddress: royaltyInfo.royaltyAddress,
                remainingGasTo: owner.address
            }
        ).send({
            from: owner.address,
            amount: toNano(2)
        }));
    
        const { id } = Contracts.getFirstEvent(traceTree, collection, 'NftCreated');
        const nftAddress = await Collections.nftAddress(collection, id);
    
        const nft = Nfts.attachDeployedWithRoyalty(nftAddress);
        await Nfts.checkInfo(nft, {
            collection: collection.address,
            id,
            owner: owner.address,
            manager: owner.address
        });
        await Nfts.checkJson(nft, TOKEN_METADATA);
        await Nfts.checkRoyaltyInfo(nft, {
            royalty: royaltyInfo.royalty,
            royaltyAddress: royaltyInfo.royaltyAddress
        });
    
        return { nft, id };
    }
    
    static async mintToken(
        collection: MultiTokenCollectionContract,
        owner: Account,
        count: number = 5
    ): Promise<{
        wallet: MultiTokenWalletContract;
        nft: NftContract;
        id: string;
    }> {
        const { traceTree } = await locklift.tracing.trace(collection.methods.mintToken({
            answerId: 0,
            tokenOwner: owner.address,
            json: TOKEN_METADATA,
            count,
            remainingGasTo: owner.address,
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        }));
    
        const { id } = Contracts.getFirstEvent(traceTree, collection, 'MultiTokenCreated');
        const walletAddress = await Collections.multiTokenWalletAddress(collection, id, owner.address);
    
        const wallet = MultiTokens.attachDeployed(walletAddress);
        await MultiTokens.checkInfo(wallet, {
            collection: collection.address,
            id,
            owner: owner.address
        });
        await MultiTokens.checkBalance(wallet, count);

        const nftAddress = await Collections.nftAddress(collection, id);
        const nft = Nfts.attachDeployed(nftAddress);
    
        await Nfts.checkInfo(nft, {
            collection: collection.address,
            id,
            owner: collection.address,
            manager: collection.address
        });
        await Nfts.checkJson(nft, TOKEN_METADATA);
    
        return { wallet, nft, id };
    }
    
    static async mintTokenWithRoyalty(
        collection: MultiTokenCollectionWithRoyaltyContract,
        owner: Account,
        count: number = 5,
        royaltyInfo: {
            royalty: number;
            royaltyAddress: Address;
        } = {
            royalty: DEFAULT_ROYALTY,
            royaltyAddress: DEFAULT_ROYALTY_ADDRESS
        }
    ): Promise<{
        wallet: MultiTokenWalletWithRoyaltyContract;
        nft: NftWithRoyaltyContract;
        id: string;
    }> {
        const { traceTree } = await locklift.tracing.trace(collection.methods.mintToken({
            answerId: 0,
            tokenOwner: owner.address,
            json: TOKEN_METADATA,
            count,
            royalty: royaltyInfo.royalty,
            royaltyAddress: royaltyInfo.royaltyAddress,
            remainingGasTo: owner.address,
            notify: false,
            payload: ''
        }).send({
            from: owner.address,
            amount: toNano(2)
        }));
    
        const { id } = Contracts.getFirstEvent(traceTree, collection, 'MultiTokenCreated');
        const walletAddress = await Collections.multiTokenWalletAddress(collection, id, owner.address);
    
        const wallet = MultiTokens.attachDeployedWithRoyalty(walletAddress);
        await MultiTokens.checkInfo(wallet, {
            collection: collection.address,
            id,
            owner: owner.address
        });
        await MultiTokens.checkBalance(wallet, count);
        await MultiTokens.checkRoyaltyInfo(wallet, {
            royalty: royaltyInfo.royalty,
            royaltyAddress: royaltyInfo.royaltyAddress        
        });

        const nftAddress = await Collections.nftAddress(collection, id);
    
        const nft = Nfts.attachDeployedWithRoyalty(nftAddress);
        await Nfts.checkInfo(nft, {
            collection: collection.address,
            id,
            owner: collection.address,
            manager: collection.address
        });
        await Nfts.checkJson(nft, TOKEN_METADATA);
        await Nfts.checkRoyaltyInfo(nft, {
            royalty: royaltyInfo.royalty,
            royaltyAddress: royaltyInfo.royaltyAddress
        });

    
        return { wallet, nft, id };
    }
}
