
use core::starknet::{ContractAddress, get_caller_address};
use starknet::storage::{Map, StorageMapReadAccess, StoragePointerWriteAccess, StoragePathEntry, StoragePointerReadAccess, StorageMapWriteAccess};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, EventSpyAssertionsTrait, spy_events, load,
};

use starkz::starkz::{IStarkzDispatcher, IStarkzDispatcherTrait};

fn deploy_contract(name: ByteArray) -> (IStarkzDispatcher, ContractAddress){
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = IStarkzDispatcher { contract_address };
    (dispatcher, contract_address)

}

// #[test]
// fn test_constructor(){
//     let (starkz, starkz_address) = deploy_contract("Starkz");

//     let counter = load(starkz_address, selector!("counter"), 1);
//     assert_eq!(counter, array![0]);

// }   


#[test]
fn test_counter(){
    let (starkz, starkz_address) = deploy_contract("Starkz");
    assert_eq!(starkz.count(),0, "counter should be zero");

    starkz.increment();
    assert_eq!(starkz.count(),1, "should have increased counter");

}

#[test]
fn test_publish(){
    let (starkz, starkz_address) = deploy_contract("Starkz");
    start_cheat_caller_address(starkz_address, 123.try_into().unwrap());
    let id = starkz.publish(
        123.try_into().unwrap(),
        'testing-the-publication',
        "https://ipfs.io/ipfs/"
    );
    assert_eq!(id, 1, "this should be the first publication");
    assert_eq!(starkz.count(),1, "should have increased counter");
    assert_eq!(starkz.get_publication(starkz.count()), "https://ipfs.io/ipfs", "ipfsHash is incorrect");
    assert_eq!(starkz.get_slug('testing-the-publication'), 1, "id should be 1");
    
    
}