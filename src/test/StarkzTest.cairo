
use core::starknet::{contract_address_const, ContractAddress, get_caller_address};
use starknet::storage::{Map, StorageMapReadAccess, StoragePointerWriteAccess, StoragePathEntry, StoragePointerReadAccess, StorageMapWriteAccess};
use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address,
    stop_cheat_caller_address, EventSpyAssertionsTrait, spy_events, load, mock_call
};
use openzeppelin_token::erc721::interface::{
    IERC721Dispatcher, IERC721DispatcherTrait, IERC721MetadataDispatcher,
    IERC721MetadataDispatcherTrait, IERC721Receiver, IERC721ReceiverDispatcher, IERC721ReceiverDispatcherTrait
};
use starkz::Starkz::{IStarkzDispatcher, IStarkzDispatcherTrait};

fn deploy_starkz() -> (IStarkzDispatcher, ContractAddress){
    let contract = declare("Starkz").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    let dispatcher = IStarkzDispatcher { contract_address };
    (dispatcher, contract_address)

}

fn deploy_receiver() -> ContractAddress {
    let contract = declare("Receiver").unwrap().contract_class();
    let mut calldata = array![];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    println!("Receiver deployed on: {:?}", contract_address);
    contract_address
}

// #[test]
// fn test_constructor(){
//     let (starkz, starkz_address) = deploy_contract("Starkz");

//     let counter = load(starkz_address, selector!("counter"), 1);
//     assert_eq!(counter, array![0]);

// }   


#[test]
fn test_counter(){
    let (starkz, starkz_address) = deploy_starkz();
    assert_eq!(starkz.count(),0, "counter should be zero");

    start_cheat_caller_address(starkz_address,contract_address_const::<'123'>());
    starkz.increment(contract_address_const::<'123'>());
    assert_eq!(starkz.count(),1, "should have increased counter");

}

#[test]
fn test_publish(){
    let (starkz, starkz_address) = deploy_starkz();
    let erc721 = IERC721Dispatcher { contract_address: starkz_address };
    let receiver = deploy_receiver();
    start_cheat_caller_address(starkz_address, receiver);
    assert_eq!(erc721.balance_of(receiver),0, "shouldnt have publications");
    let id = starkz.publish(
        receiver,
        'testing-the-publication',
        "https://ipfs.io/ipfs"
    );
    assert_eq!(erc721.balance_of(receiver),1, "should have one publication");
    assert_eq!(id, 1, "this should be the first publication");
    assert_eq!(starkz.count(),1, "should have increased counter");
    assert_eq!(starkz.get_publication(starkz.count()), "https://ipfs.io/ipfs", "ipfsHash is incorrect");
    assert_eq!(starkz.get_slug('testing-the-publication'), 1, "id should be 1");
    stop_cheat_caller_address(starkz_address);
    
}