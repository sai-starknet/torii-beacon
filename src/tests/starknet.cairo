use starknet::{ClassHash, ContractAddress};
use core::metaprogramming::TypeEqual;
use dojo_beacon::starknet::{calculate_contract_address, calculate_udc_contract_address};
use starknet::{syscalls::{get_class_hash_at_syscall}, SyscallResultTrait};

#[derive(Drop)]
struct DeployContactTestConst<const S: usize> {
    class_hash: felt252,
    deployer_address: felt252,
    salt: felt252,
    calldata: [felt252; S],
    expected_address: felt252,
}

#[derive(Drop)]
struct DeployContactTest {
    class_hash: ClassHash,
    deployer_address: ContractAddress,
    salt: felt252,
    calldata: Span<felt252>,
    expected_address: ContractAddress,
}

impl DeployContactTestConstTryIntoDeployContactTest<
    const S: usize, -TypeEqual<[felt252; S], [felt252; 0]>,
> of TryInto<DeployContactTestConst<S>, DeployContactTest> {
    fn try_into(self: DeployContactTestConst<S>) -> Option<DeployContactTest> {
        // let span: Span<felt252> = self.calldata.span();
        Option::Some(
            DeployContactTest {
                class_hash: self.class_hash.try_into()?,
                deployer_address: self.deployer_address.try_into()?,
                salt: self.salt,
                calldata: BoxTrait::new(@self.calldata).span(),
                expected_address: self.expected_address.try_into()?,
            },
        )
    }
}

impl DeployContactTestConst0TryIntoDeployContactTest of TryInto<
    DeployContactTestConst<0>, DeployContactTest,
> {
    fn try_into(self: DeployContactTestConst<0>) -> Option<DeployContactTest> {
        // let span: Span<felt252> = self.calldata.span();
        Option::Some(
            DeployContactTest {
                class_hash: self.class_hash.try_into()?,
                deployer_address: self.deployer_address.try_into()?,
                salt: self.salt,
                calldata: [].span(),
                expected_address: self.expected_address.try_into()?,
            },
        )
    }
}

const UDC_TEST_1: DeployContactTestConst = DeployContactTestConst {
    class_hash: 0x045575a88cc5cef1e444c77ce60b7b4c9e73a01cbbe20926d5a4c72a94011410,
    deployer_address: 0x0,
    salt: 0x04226e134e72f57c0008063cb67413f6e87f2d68fb44b8277803718109f0ec14,
    calldata: [0x045575a88cc5cef1e444c77ce60b7b4c9e73a01cbbe20926d5a4c72a94011410],
    expected_address: 0x26fe89cb538b9dea906afda6997f39796830cd5f093c46d62a926871cd75623,
};

const UDC_TEST_2: DeployContactTestConst = DeployContactTestConst {
    class_hash: 0x036078334509b514626504edc9fb252328d1a240e4e948bef8d0c08dff45927f,
    deployer_address: 0x0,
    salt: 0x0441bdd54a127c1ac9354abba03cf31b8db1a194307a71dd560ebdb7c838cad0,
    calldata: [0x0, 0x0441bdd54a127c1ac9354abba03cf31b8db1a194307a71dd560ebdb7c838cad0, 0x1],
    expected_address: 0x079e7d055ee607f7eaedb046bdd02305e7e5c35da376f5d2e3b911d695137f24,
};

const UDC_TEST_3: DeployContactTestConst = DeployContactTestConst {
    class_hash: 0x04904ec9bb124e7a46a1894d516032cd8876e4ea69908ead8242482c2972c78d,
    deployer_address: 0x0,
    salt: 0x79da44d4ba41e6b0,
    calldata: [0x04ba5ae775eb7da75f092b3b30b03bce15c3476337ef5f9e3cdf18db7a7534bd, 0x0, 0x0, 0x0],
    expected_address: 0xdfca26711708d9f58d8bed590af05e1c62b04f48be44e8948ecde08d121d78,
};

const UDC_TEST_4: DeployContactTestConst = DeployContactTestConst {
    class_hash: 0x016342ade8a7cc8296920731bc34b5a6530f5ee1dc1bfd3cc83cb3f519d6530a,
    deployer_address: 0x000f9e998b2853e6d01f3ae3c598c754c1b9a7bd398fec7657de022f3b778679,
    salt: 0x01cf15d46087c8237c2055c1ca378f3ed64c248ad6d187ca24f22d287c63f941,
    calldata: [],
    expected_address: 0x037f5d7898454f5b2662010e28dabd19fa60de55224f49e4ced220b6c649b956,
};

const UDC_TEST_5: DeployContactTestConst = DeployContactTestConst {
    class_hash: 0x0316c001d23331128a3c3d58051584d38ebb373047996784bd9aca12387f6564,
    deployer_address: 0x000f9e998b2853e6d01f3ae3c598c754c1b9a7bd398fec7657de022f3b778679,
    salt: 0x87f182e3e897161efc9858fcdade403d6442807b1e775e30e95831ed1fbbcb,
    calldata: [0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7],
    expected_address: 0x05238954c4ca9bb7c40a1630770e01dabfa28191eaf1fc16c327de65191e46a4,
};

#[generate_trait]
impl DeployContractTest of DeployContractTestTrait {
    fn calculate_contract_address(self: @DeployContactTest) -> ContractAddress {
        calculate_contract_address(
            *self.deployer_address, *self.salt, *self.class_hash, *self.calldata,
        )
    }

    fn calculate_udc_contract_address(self: @DeployContactTest) -> ContractAddress {
        calculate_udc_contract_address(
            *self.deployer_address, *self.salt, *self.class_hash, *self.calldata,
        )
    }
}


#[test]
fn test_calculate_udc_contract_address() {
    let tests: Span<DeployContactTest> = [
        UDC_TEST_1.try_into().unwrap(), UDC_TEST_2.try_into().unwrap(),
        UDC_TEST_3.try_into().unwrap(), UDC_TEST_4.try_into().unwrap(),
        UDC_TEST_5.try_into().unwrap(),
    ]
        .span();

    for test in tests {
        let calculated_address: felt252 = test.calculate_udc_contract_address().into();
        let expected_address: felt252 = (*test.expected_address).into();
        println!("0x{calculated_address:x}\n0x{expected_address:x}\n--------");
    }
}

#[test]
fn test_contract_hash() {
    let contract_hash = get_class_hash_at_syscall(0x0.try_into().unwrap()).unwrap_syscall();
    println!("{:?}", contract_hash);
}
