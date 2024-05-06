import { Deployer, Reporter, UserStorage } from '@solarity/hardhat-migrate';
import { parseConfig } from './helpers/config-parser';
import {
  AGEN__factory,
  ERC1967Proxy__factory,
  L2MessageReceiver__factory,
  L2TokenReceiver__factory,
  NonfungiblePositionManagerMock__factory,
  StETHMock__factory,
  SwapRouterMock__factory,
  WStETHMock__factory,
} from '@/generated-types/ethers';
import { IL2TokenReceiver } from '@/generated-types/ethers/contracts/L2TokenReceiver';
import { Proxy__factory } from '@/generated-types/ethers/factories/contracts';
import { ethers, upgrades } from 'hardhat';
import { UpgradeOptions } from '@openzeppelin/hardhat-upgrades';

module.exports = async function (deployer: Deployer) {
  const config = parseConfig(await deployer.getChainId());
  const [owner] = await ethers.getSigners();
  console.log({ config, toDeployMocks: config.L2 });
  let WStETH: string;
  let swapRouter: string;
  let nonfungiblePositionManager: string;
  let stETH: string;

  if (config.L2) {
    WStETH = config.L2.wStEth;
    swapRouter = config.L2.swapRouter;
    nonfungiblePositionManager = config.L2.nonfungiblePositionManager;
  } else {
    // deploy mock
    const stETHMock = await deployer.deploy(StETHMock__factory, [], { name: 'StETH on L2' });
    stETH = await stETHMock.getAddress();

    const wStEthMock = await deployer.deploy(WStETHMock__factory, [stETH], { name: 'Wrapped stETH on L2' });
    WStETH = await wStEthMock.getAddress();

    const swapRouterMock = await deployer.deploy(SwapRouterMock__factory);
    swapRouter = await swapRouterMock.getAddress();

    const nonfungiblePositionManagerMock = await deployer.deploy(NonfungiblePositionManagerMock__factory);
    nonfungiblePositionManager = await nonfungiblePositionManagerMock.getAddress();
  }

  async function deployMockStakedETH() {
    const stakedETH = await deployer.deploy(StETHMock__factory, [], { name: 'StETH on Testnet' });
    const stakedETHProxy = await deployer.deploy(ERC1967Proxy__factory, [stakedETH, '0x'], {
      name: 'Mock Staked ETH Proxy'
    })
    stETH = await stakedETH.getAddress();
    console.log('stETH ADD: ', { stETH, owner: owner.getAddress() });

    // await stakedETH.initialize(owner.address);
    const StakedETHMock = StETHMock__factory.connect(
      await stakedETHProxy.getAddress(),
      await deployer.getSigner()
    )
    await StakedETHMock.initialize(owner.address)
    // const swapRouterMock = await deployer.deploy(SwapRouterMock__factory);
    // swapRouter = await swapRouterMock.getAddress();
    // console.log('swapRouterMock ADD: ', swapRouter);

    // const nonfungiblePositionManagerMock = await deployer.deploy(NonfungiblePositionManagerMock__factory);
    // nonfungiblePositionManager = await nonfungiblePositionManagerMock.getAddress();
  }

  await deployMockStakedETH();

  const AGENTokenImpl = await deployer.deploy(AGEN__factory, [], { name: "AGEN Token" });
  const AGENTokenProxy = await deployer.deploy(ERC1967Proxy__factory, [AGENTokenImpl, '0x'], {
    name: "AGEN Token Proxy"
  })

  const AGENToken = AGEN__factory.connect(
    await AGENTokenProxy.getAddress(),
    await deployer.getSigner()
  )

  await AGENToken.initialize(owner.address, ['0xCbcb2a6E6b4ed4a8D281709c831960a31547f738', '0x552375B8BC807F30065Dca9A5828B645D64F53Ab'])

  if (!UserStorage.has('AGEN')) UserStorage.set('AGEN', AGENTokenImpl);

  // const AGENProxy = await deployer.deploy(Proxy__factory, []);

  console.log({ AGENTokenImpl: Object.keys(AGENTokenImpl), AGENTokenProxy: Object.keys(AGENTokenProxy) })
  // console.log({ agenProxyAddress, implementationContract })

  const swapParams: IL2TokenReceiver.SwapParamsStruct = {
    tokenIn: WStETH,
    tokenOut: AGENTokenImpl,
    fee: config.swapParams.fee,
    sqrtPriceLimitX96: config.swapParams.sqrtPriceLimitX96,
  };

  const l2TokenReceiverImpl = await deployer.deploy(L2TokenReceiver__factory);
  const l2TokenReceiverProxy = await deployer.deploy(ERC1967Proxy__factory, [l2TokenReceiverImpl, '0x'], {
    name: 'L2TokenReceiver Proxy',
  });
  if (!UserStorage.has('L2TokenReceiver Proxy'))
    UserStorage.set('L2TokenReceiver Proxy', await l2TokenReceiverProxy.getAddress());
  const l2TokenReceiver = L2TokenReceiver__factory.connect(
    await l2TokenReceiverProxy.getAddress(),
    await deployer.getSigner(),
  );
  await l2TokenReceiver.L2TokenReceiver__init(swapRouter, nonfungiblePositionManager, swapParams);

  const l2MessageReceiverImpl = await deployer.deploy(L2MessageReceiver__factory);
  const l2MessageReceiverProxy = await deployer.deploy(ERC1967Proxy__factory, [l2MessageReceiverImpl, '0x'], {
    name: 'L2MessageReceiver Proxy',
  });
  if (!UserStorage.has('L2MessageReceiver Proxy'))
    UserStorage.set('L2MessageReceiver Proxy', await l2MessageReceiverProxy.getAddress());
  const l2MessageReceiver = L2MessageReceiver__factory.connect(
    await l2MessageReceiverProxy.getAddress(),
    await deployer.getSigner(),
  );
  await l2MessageReceiver.L2MessageReceiver__init();

  // await AGENTokenImpl.transferOwnership(l2MessageReceiver)
  // await AGENTokenImpl.transferOwnership((await l2MessageReceiver.getAddress()).toString())

  Reporter.reportContracts(
    ['L2TokenReceiver', await l2TokenReceiver.getAddress()],
    ['L2MessageReceiver', await l2MessageReceiver.getAddress()],
    ['Staked Ether', stETH],
    ['AGEN', await AGENTokenImpl.getAddress()],
  );
};
