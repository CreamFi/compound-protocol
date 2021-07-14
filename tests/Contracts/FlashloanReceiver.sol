pragma solidity ^0.5.16;

import "./ERC20.sol";
import "../../contracts/CCollateralCapErc20.sol";
import "../../contracts/CWrappedNative.sol";
import "../../contracts/SafeMath.sol";

// FlashloanReceiver is a simple flashloan receiver implementation for testing
contract FlashloanReceiver is ERC3156FlashBorrowerInterface{
    using SafeMath for uint256;

    uint totalBorrows;
    address borrowToken;

    function doFlashloan(address cToken, uint borrowAmount, uint repayAmount) external {
        borrowToken = CCollateralCapErc20(cToken).underlying();
        uint balanceBefore = ERC20(borrowToken).balanceOf(address(this));
        bytes memory data = abi.encode(cToken, borrowAmount, repayAmount);
        totalBorrows = CCollateralCapErc20(cToken).totalBorrows();
        CCollateralCapErc20(cToken).flashLoan(this, borrowToken, borrowAmount, data);
        uint balanceAfter = ERC20(borrowToken).balanceOf(address(this));
        require(balanceAfter == balanceBefore.add(borrowAmount).sub(repayAmount), "Balance inconsistent");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        (address cToken, uint borrowAmount, uint repayAmount) = abi.decode(data, (address, uint, uint));
        require(amount == borrowAmount, "Params not match");
        uint totalBorrowsAfter = CCollateralCapErc20(cToken).totalBorrows();
        require(totalBorrows.add(borrowAmount) == totalBorrowsAfter, "totalBorrow mismatch");
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndMint is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;
    uint totalBorrows;
    address borrowToken;


    function doFlashloan(address cToken, uint borrowAmount) external {
        borrowToken = CCollateralCapErc20(cToken).underlying();
        bytes memory data = abi.encode(cToken);
        CCollateralCapErc20(cToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        address cToken = abi.decode(data, (address));
        CCollateralCapErc20(cToken).mint(amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanAndRepayBorrow is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;
    address borrowToken;
    function doFlashloan(address cToken, uint borrowAmount) external {
        borrowToken = CCollateralCapErc20(cToken).underlying();
        bytes memory data = abi.encode(cToken);
        CCollateralCapErc20(cToken).flashLoan(this,borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));
        address cToken = abi.decode(data, (address));
        CCollateralCapErc20(cToken).repayBorrow(amount.add(fee));
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanTwice is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;
    address borrowToken;

    function doFlashloan(address cToken, uint borrowAmount) external {
        borrowToken = CCollateralCapErc20(cToken).underlying();
        bytes memory data = abi.encode(cToken);
        CCollateralCapErc20(cToken).flashLoan(this, borrowToken, borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        ERC20(borrowToken).approve(msg.sender, amount.add(fee));       
        address cToken = abi.decode(data, (address));
        CCollateralCapErc20(cToken).flashLoan(this,borrowToken, amount, data);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}

contract FlashloanReceiverNative is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;

    uint totalBorrows;

    function doFlashloan(address payable cToken, uint borrowAmount, uint repayAmount) external {
        uint balanceBefore = address(this).balance;
        bytes memory data = abi.encode(cToken, borrowAmount, repayAmount);
        totalBorrows = CWrappedNative(cToken).totalBorrows();
        CWrappedNative(cToken).flashLoan(this,address(0), borrowAmount, data);
        uint balanceAfter = address(this).balance;
        require(balanceAfter == balanceBefore.add(borrowAmount).sub(repayAmount), "Balance inconsistent");
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
        CWrappedNative(cToken).flashLoan(this, address(0), borrowAmount, data);
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
        CWrappedNative(cToken).flashLoan(this, address(0), borrowAmount, data);
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
    address borrowToken;

    function doFlashloan(address payable cToken, uint borrowAmount) external {
        borrowToken = CCollateralCapErc20(cToken).underlying();
        bytes memory data = abi.encode(cToken);
        CWrappedNative(cToken).flashLoan(this, address(0), borrowAmount, data);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        address payable cToken = abi.decode(data, (address));
        CWrappedNative(cToken).flashLoan(this,address(0), amount, data);
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }
}
