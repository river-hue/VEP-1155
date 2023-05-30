import { AbiEventName, Address, Contract, DecodedEventWithTransaction } from 'locklift';
import { ViewTracingTree } from 'locklift/internal/tracing/viewTraceTree/viewTracingTree';
import { expect } from "chai";

type EventNames<Abi> = DecodedEventWithTransaction<Abi, AbiEventName<Abi>>["event"];

export class Contracts {
    static async exists(address: Address): Promise<boolean> {
        const { state } = await locklift.provider.getFullContractState({address});
        return (state && state.isDeployed) ? true : false;
    }
    
    static async getContractBalance(address: Address): Promise<number> {
        return Number(await locklift.provider.getBalance(address));
    }

    static async getCodeHash(address: Address): Promise<string | undefined> {
        return locklift.provider.getFullContractState({address}).then(({state}) => state?.codeHash)
    }

    static async checkExists(address: Address, expected: boolean) {
        const actual = await Contracts.exists(address);
        expect(actual).to.be.eq(expected, 'Wrong contract state');
    }

    static async checkContractBalance(address: Address, expected: number) {
        const actual = await Contracts.getContractBalance(address);
        expect(actual).to.be.eq(expected, 'Wrong contract balance');
    }

    static getFirstEvent<T>(traceTree: ViewTracingTree, contract: Contract<T>, eventName: EventNames<T>): any {
        const events = traceTree?.findEventsForContract({
            contract,
            name: eventName
        });
        expect(events).not.to.be.eq(undefined, `Events not found. Expected: ${eventName}`);
        expect(events.length).to.be.above(0, `Event ${eventName} not found`);
        return events[0];
    }
}
