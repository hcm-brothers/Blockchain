import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "@ethersproject/contracts";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import * as chai from "chai";
import chaiAsPromised from "chai-as-promised";
import { keccak256 } from "ethers/lib/utils";
chai.use(chaiAsPromised);

function parseEther(amount: Number) {
  return ethers.utils.parseUnits(amount.toString(), 18);
}

describe("Vault", function () {
  let owner: SignerWithAddress,
    alice: SignerWithAddress,
    bob: SignerWithAddress,
    carol: SignerWithAddress;

  let vault: Contract;
  let token: Contract;

  beforeEach(async () => {
    await ethers.provider.send("hardhat_reset", []);
    [owner, alice, bob, carol] = await ethers.getSigners();

    const Vault = await ethers.getContractFactory("Vault", owner);
    vault = await Vault.deploy();
    const Token = await ethers.getContractFactory("Darts", owner);
    token = await Token.deploy();
    await vault.setToken(token.address);
  });

  //* Happy Path
  it("Should deposit into the Vault", async () => {
    //* give Alice some token
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));

    //* approve token to vault
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));

    await vault.connect(alice).deposit(parseEther(500 * 10 ** 3));

    expect(await token.balanceOf(vault.address)).equal(
      parseEther(500 * 10 ** 3)
    );
  });

  it("Should withdraw", async () => {
    //* grant withdrawer role to Bob
    let WITHDRAWER_ROLE = keccak256(Buffer.from("WITHDRAWER_ROLE")).toString();
    await vault.grantRole(WITHDRAWER_ROLE, bob.address);

    //* setter vault functions
    await vault.setWithdrawalEnabled(true);
    await vault.setMaxWithdrawalAmount(parseEther(1 * 10 ** 6));

    //* Give Alice some token
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));

    //* Alice approve token to vault
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));

    await vault.connect(alice).deposit(parseEther(500 * 10 ** 3));

    //* bob withdraw into alice address
    await vault.connect(bob).withdraw(parseEther(300 * 10 ** 3), alice.address);

    expect(await token.balanceOf(vault.address)).equal(
      parseEther(200 * 10 ** 3)
    );
    expect(await token.balanceOf(alice.address)).equal(
      parseEther(800 * 10 ** 3)
    );
  });

  //* Unhappy Path
  it("Should not deposit, Insufficient account balance", async () => {
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));
    await expect(
      vault.connect(alice).deposit(parseEther(2 * 10 ** 6))
    ).revertedWith("ERC20: insufficient allowance");
  });

  it("Should not withdraw, Withdraw is not available ", async () => {
    //* grant withdrawer role to Bob
    let WITHDRAWER_ROLE = keccak256(Buffer.from("WITHDRAWER_ROLE")).toString();
    await vault.grantRole(WITHDRAWER_ROLE, bob.address);

    //* setter vault functions
    await vault.setWithdrawalEnabled(false);
    await vault.setMaxWithdrawalAmount(parseEther(1 * 10 ** 6));

    //* alice deposit into the vault
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));
    await vault.connect(alice).deposit(parseEther(500 * 10 ** 3));

    //* bob withdraw into alice address
    await expect(
      vault.connect(bob).withdraw(parseEther(300 * 10 ** 3), alice.address)
    ).revertedWith("Vault: Withdrawals are disabled");
  });

  it("Should not withdraw, Exceed maximum amount ", async () => {
    //* grant withdrawer role to Bob
    let WITHDRAWER_ROLE = keccak256(Buffer.from("WITHDRAWER_ROLE")).toString();
    await vault.grantRole(WITHDRAWER_ROLE, bob.address);

    //* setter vault functions
    await vault.setWithdrawalEnabled(true);
    await vault.setMaxWithdrawalAmount(parseEther(1 * 10 ** 3));

    //* Alice deposit into the vault
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));
    await vault.connect(alice).deposit(parseEther(500 * 10 ** 3));

    //* Bob withdraw into alice address
    await expect(
      vault.connect(bob).withdraw(parseEther(2 * 10 ** 3), alice.address)
    ).revertedWith("Vault: Amount exceeds max withdrawal amount");
  });

  it("Should not withdraw, Caller is not a withdrawer", async () => {
    //* grant withdrawer role to Bob
    let WITHDRAWER_ROLE = keccak256(Buffer.from("WITHDRAWER_ROLE")).toString();
    await vault.grantRole(WITHDRAWER_ROLE, bob.address);

    //* setter vault functions
    await vault.setWithdrawalEnabled(true);
    await vault.setMaxWithdrawalAmount(parseEther(1 * 10 ** 3));

    //* alice deposit into the vault
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));
    await vault.connect(alice).deposit(parseEther(500 * 10 ** 3));

    //* bob withdraw into alice address
    await expect(
      vault.connect(carol).withdraw(parseEther(1 * 10 ** 3), alice.address)
    ).revertedWith("Vault: Caller is not a withdrawer");
  });

  it("Should not withdraw, ERC20: transfer amount exceeds balance", async () => {
    //* grant withdrawer role to Bob
    let WITHDRAWER_ROLE = keccak256(Buffer.from("WITHDRAWER_ROLE")).toString();
    await vault.grantRole(WITHDRAWER_ROLE, bob.address);

    //* setter vault functions
    await vault.setWithdrawalEnabled(true);
    await vault.setMaxWithdrawalAmount(parseEther(5 * 10 ** 3));

    //* alice deposit into the vault
    await token.transfer(alice.address, parseEther(1 * 10 ** 6));
    await token
      .connect(alice)
      .approve(vault.address, token.balanceOf(alice.address));
    await vault.connect(alice).deposit(parseEther(2 * 10 ** 3));

    //* bob withdraw into alice address
    await expect(
      vault.connect(bob).withdraw(parseEther(3 * 10 ** 3), alice.address)
    ).revertedWith("ERC20: transfer amount exceeds balance");
  });
});
