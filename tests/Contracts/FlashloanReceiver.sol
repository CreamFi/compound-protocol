pragma solidity ^0.5.16;

import "./ERC20.sol";
import "../../contracts/CCollateralCapErc20.sol";
import "../../contracts/CWrappedNative.sol";
import "../../contracts/SafeMath.sol";

// FlashloanReceiver is a simple flashloan receiver implementation for testing
contract FlashloanReceiver is IFlashloanReceiver, ERC3156FlashBorrowerInterface{
    using SafeMath for uint256;

    uint totalBorrows;

    function doFlashloan(address cToken, uint borrowAmount, uint repayAmount) external {
        uint balanceBefore = ERC20(CCollateralCapErc20(cToken).underlying()).balanceOf(address(this));
        bytes memory data = abi.encode(cToken, borrowAmount, repayAmount);
        totalBorrows = CCollateralCapErc20(cToken).totalBorrows();
        CCollateralCapErc20(cToken).flashLoan(address(this), borrowAmount, data);
        uint balanceAfter = ERC20(CCollateralCapErc20(cToken).underlying()).balanceOf(address(this));
        require(balanceAfter == balanceBefore.add(borrowAmount).sub(repayAmount), "Balance inconsistent");
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
      (address cToken, uint borrowAmount, uint repayAmount) = abi.decode(params, (address, uint, uint));
      require(underlying == CCollateralCapErc20(cToken).underlying(), "Params not match");
      require(amount == borrowAmount, "Params not match");
      uint totalBorrowsAfter = CCollateralCapErc20(cToken).totalBorrows();
      require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
      require(ERC20(underlying).transfer(cToken, repayAmount), "Transfer fund back failed");
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        (address cToken, uint borrowAmount, uint repayAmount) = abi.decode(data, (address, uint, uint));
        require(token == CCollateralCapErc20(cToken).underlying(), "Params not match123");
        require(amount == borrowAmount, "Params not match");
        uint totalBorrowsAfter = CCollateralCapErc20(cToken).totalBorrows();
        require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
        require(ERC20(token).transfer(cToken, repayAmount), "Transfer fund back failed");
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndMint is IFlashloanReceiver, ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    function doFlashloan(address cToken, uint borrowAmount) external {
        bytes memory data = abi.encode(cToken);
        CCollateralCapErc20(cToken).flashLoan(address(this), borrowAmount, data);
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address cToken = abi.decode(params, (address));
        CCollateralCapErc20(cToken).mint(amount.add(fee));
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address cToken = abi.decode(data, (address));
        CCollateralCapErc20(cToken).mint(amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndRepayBorrow is IFlashloanReceiver, ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    function doFlashloan(address cToken, uint borrowAmount) external {
        bytes memory data = abi.encode(cToken);
        CCollateralCapErc20(cToken).flashLoan(address(this), borrowAmount, data);
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address cToken = abi.decode(params, (address));
        CCollateralCapErc20(cToken).repayBorrow(amount.add(fee));
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address cToken = abi.decode(data, (address));
        CCollateralCapErc20(cToken).repayBorrow(amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanTwice is IFlashloanReceiver, ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    function doFlashloan(address cToken, uint borrowAmount) external {
        bytes memory data = abi.encode(cToken);
        CCollateralCapErc20(cToken).flashLoan(address(this), borrowAmount, data);
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address cToken = abi.decode(params, (address));
        CCollateralCapErc20(cToken).flashLoan(address(this), amount, params);
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address cToken = abi.decode(data, (address));
        CCollateralCapErc20(cToken).flashLoan(address(this), amount, data);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanReceiverNative is IFlashloanReceiver, ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    uint totalBorrows;

    function doFlashloan(address payable cToken, uint borrowAmount, uint repayAmount) external {
        uint balanceBefore = address(this).balance;
        bytes memory data = abi.encode(cToken, borrowAmount, repayAmount);
        totalBorrows = CWrappedNative(cToken).totalBorrows();
        CWrappedNative(cToken).flashLoan(address(this), borrowAmount, data);
        uint balanceAfter = address(this).balance;
        require(balanceAfter == balanceBefore.add(borrowAmount).sub(repayAmount), "Balance inconsistent");
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
      (address payable cToken, uint borrowAmount, uint repayAmount) = abi.decode(params, (address, uint, uint));
      require(underlying == address(0), "Params not match");
      require(amount == borrowAmount, "Params not match");
      uint totalBorrowsAfter = CWrappedNative(cToken).totalBorrows();
      require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
      cToken.transfer(repayAmount);
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        (address payable cToken, uint borrowAmount, uint repayAmount) = abi.decode(data, (address, uint, uint));
        require(token == address(0), "Params not match");
        require(amount == borrowAmount, "Params not match");
        uint totalBorrowsAfter = CWrappedNative(cToken).totalBorrows();
        require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
        cToken.transfer(repayAmount);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

    function () external payable {}
}

contract FlashloanAndMintNative is FlashloanReceiverNative {
    using SafeMath for uint256;

    function doFlashloan(address payable cToken, uint borrowAmount) external {
        bytes memory data = abi.encode(cToken);
        CWrappedNative(cToken).flashLoan(address(this), borrowAmount, data);
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address payable cToken = abi.decode(params, (address));
        CWrappedNative(cToken).mint(amount.add(fee));
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address payable cToken = abi.decode(data, (address));
        CWrappedNative(cToken).mint(amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndRepayBorrowNative is FlashloanReceiverNative {
    using SafeMath for uint256;

    function doFlashloan(address payable cToken, uint borrowAmount) external {
        bytes memory data = abi.encode(cToken);
        CWrappedNative(cToken).flashLoan(address(this), borrowAmount, data);
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address payable cToken = abi.decode(params, (address));
        CWrappedNative(cToken).repayBorrow(amount.add(fee));
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address payable cToken = abi.decode(data, (address));
        CWrappedNative(cToken).repayBorrow(amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanTwiceNative is FlashloanReceiverNative {
    using SafeMath for uint256;

    function doFlashloan(address payable cToken, uint borrowAmount) external {
        bytes memory data = abi.encode(cToken);
        CWrappedNative(cToken).flashLoan(address(this), borrowAmount, data);
    }

    function executeOperation(address sender, address underlying, uint amount, uint fee, bytes calldata params) external {
        address payable cToken = abi.decode(params, (address));
        CWrappedNative(cToken).flashLoan(address(this), amount, params);
    }
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address payable cToken = abi.decode(data, (address));
        CWrappedNative(cToken).flashLoan(address(this), amount, data);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}
