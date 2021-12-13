pragma solidity ^0.5.16;
//cToken
import "./CErc20Delegator.sol";
import "./CErc20Delegate.sol";
import "./CTokenInterfaces.sol";

//comptroller
import "./Unitroller.sol";
import "./ComptrollerG1.sol";
//interestModel
import "./WhitePaperInterestRateModel.sol";
//priceOracle
import "./SimplePriceOracle.sol";

contract DeployCompound {
    CErc20Delegator public cUni;
    CErc20Delegate	public cUniDelegate;
    Unitroller		public unitroller;
    ComptrollerG1	public comptroller;
    ComptrollerG1	public unitrollerProxy;
    WhitePaperInterestRateModel	public whitePaper;
    SimplePriceOracle	public priceOracle;
    
    constructor(address underlying_) public {
        //先初始化priceOracle
        priceOracle = new SimplePriceOracle();
        //再初始化whitepaper
        whitePaper = new WhitePaperInterestRateModel(50000000000000000, 120000000000000000);
        //再初始化comptroller
        unitroller = new Unitroller();
        comptroller = new ComptrollerG1();
        unitrollerProxy = ComptrollerG1(address(unitroller));

        unitroller._setPendingImplementation(address(comptroller));
        comptroller._become(unitroller, priceOracle, 500000000000000000, 20, true);

       	unitrollerProxy._setPriceOracle(priceOracle);
        unitrollerProxy._setCloseFactor(500000000000000000);
        unitrollerProxy._setMaxAssets(20);
        unitrollerProxy._setLiquidationIncentive(1080000000000000000);
        //最后初始化cToken

        cUniDelegate = new CErc20Delegate();
        bytes memory data = new bytes(0x00);
        cUni = new CErc20Delegator(
            					   underlying_, 
                                   comptroller,
                                   InterestRateModel(address(whitePaper)),
                                   200000000000000000000000000,
                                   "Compound Uniswap",
                                   "cUNI",
                                   8,
                                   address(uint160(address(this))),
                                   address(cUniDelegate),
                                   data
                                  );
        cUni._setImplementation(address(cUniDelegate), false, data);
        cUni._setReserveFactor(250000000000000000);
        
        //设置uni的价格
        priceOracle.setUnderlyingPrice(CToken(address(cUni)), 1e18);
        //支持的markets
        unitrollerProxy._supportMarket(CToken(address(cUni)));
        unitrollerProxy._setCollateralFactor(CToken(address(cUni)), 600000000000000000);
    }
}