use core::starknet::{ContractAddress, get_caller_address};

#[starknet::interface]
pub trait IStarkz<T> {
    fn DATA(self: @T, success: bool) -> Span<felt252>;

    fn count(self: @T) -> u256;
    fn increment(ref self: T);

    fn publish(ref self: T, owner: ContractAddress, slug: felt252, ipfsHash: ByteArray) -> u256;
    fn get_publication(self: @T, id: u256) -> ByteArray;
}

#[starknet::contract]
mod Starkz {
    use ERC721Component::InternalTrait;
    use starknet::storage::{Map, StorageMapReadAccess, StoragePointerWriteAccess, StoragePathEntry, StoragePointerReadAccess, StorageMapWriteAccess};
    use openzeppelin_introspection::src5::SRC5Component;
    use openzeppelin_token::erc721::{ERC721Component, ERC721HooksEmptyImpl};

    use super::{ContractAddress, IStarkz, get_caller_address};

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    // impl ERC721InternalImpl = ERC721Component::ERC721InternalImpl<ContractState>;
    
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,

        #[substorage(v0)]
        src5: SRC5Component::Storage,

        counter: u256,
        slugs: Map<felt252, u256>,
        publications: Map<u256, ByteArray>,
        
    }       

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
    ){

        let name: ByteArray = "StarkZ";
        let symbol: ByteArray = "SKZ";
        let base_uri: ByteArray = " ";
        
        self.erc721.initializer(name,symbol,base_uri);
        self.counter.write(0);
    }

    #[abi(embed_v0)]
    impl StarkzImpl of IStarkz<ContractState>{

        fn DATA(self: @ContractState, success: bool) -> Span<felt252> {
            let value = if success {
                'SUCCESS'
            } else {
                'FAILURE'
            };
            array![value].span()
        }

        fn count(self: @ContractState) -> u256 {
            self.counter.read()
        }

        fn increment(ref self: ContractState){
            self.counter.write(self.counter.read() + 1)
        }

        fn publish(ref self: ContractState, owner: ContractAddress, slug: felt252, ipfsHash: ByteArray) -> u256 {
            assert(self.slugs.read(slug) == 0, 'choose another slug'); //essa msg tem que ir pro front
            assert(owner == get_caller_address(), 'owner cant publish');
            
            self.increment();
            let id = self.count();
            self.slugs.entry(slug).write(id);
            self.publications.entry(id).write(ipfsHash);
            self.erc721.safe_mint(owner,id,self.DATA(true));
            id

        }

        fn get_publication(self: @ContractState, id: u256) -> ByteArray {
            self.publications.entry(id).read()
        } // aí só dar fetch nessa url no front
    }
}
