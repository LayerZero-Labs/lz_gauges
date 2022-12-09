const { expect } = require("chai")
const { ethers } = require("hardhat")
const { BigNumber } = require("ethers");

describe("VotingEscrowMock", function () {
    let ve, ove, ovec, parentEndpoint, childEndpoint
    let VE, OVE, OVEC, LZEndpointMock, user
    const parentChainId = 1
    const childChainId = 2

    before(async function () {
        LZEndpointMock = await ethers.getContractFactory("LZEndpointMock")
        VE = await ethers.getContractFactory("VotingEscrowMock")
        OVE = await ethers.getContractFactory("OmniVotingEscrow")
        OVEC = await ethers.getContractFactory("OmniVotingEscrowChild")
        user = (await ethers.getSigners())[1].address
    })

    // TODO convert to utils/helpers.js
    beforeEach(async function () {
        // parent chain contracts
        parentEndpoint = await LZEndpointMock.deploy(parentChainId)
        ve = await VE.deploy()
        ove = await OVE.deploy(parentEndpoint.address, ve.address)

        // child chain contracts
        childEndpoint = await LZEndpointMock.deploy(childChainId)
        ovec = await OVEC.deploy(childEndpoint.address)

        // internal bookkeeping for endpoints (not part of a real deploy, just for this test)
        parentEndpoint.setDestLzEndpoint(ovec.address, childEndpoint.address)
        childEndpoint.setDestLzEndpoint(ove.address, parentEndpoint.address)

        await ove.setTrustedRemoteAddress(childChainId, (ethers.utils.solidityPack(["address"], [ovec.address]))) // for A, set B
        await ovec.setTrustedRemoteAddress(parentChainId, (ethers.utils.solidityPack(["address"], [ove.address]))) // for B, set A
    })

    it.skip("addresses", async function () {
        console.log(parentEndpoint.address)
        console.log(ve.address)
        console.log(ove.address)
        console.log(childEndpoint.address)
        console.log(ovec.address)
    })

    it("VotingEscrowMock.vy can set and get values: ", async function () {
        let epoch = 10
        let point = {
            bias: "95908345856757702214638",
            slope: "5305473300535549",
            ts: "1648652538",
            blk: "14488225"
        }

        let user_epoch = 5
        let user_point = {
            bias: "959083458567577022146",
            slope: "53054733005355",
            ts: "16486525",
            blk: "144882"
        }

        let empty_point= {
            bias: 0,
            slope: 0,
            ts: 0,
            blk: 0
        }

        expect(await ve.epoch()).to.equal(0)
        await ve.set_epoch(epoch)
        expect(await ve.epoch()).to.equal(epoch)

        expect(await ve.user_point_epoch(user)).to.equal(0)
        await ve.set_user_point_epoch(user, user_epoch)
        expect(await ve.user_point_epoch(user)).to.equal(user_epoch)

        let contractPoint = await ve.point_history(epoch)
        expect(contractPoint.bias).to.equal(empty_point.bias)
        expect(contractPoint.slope).to.equal(empty_point.slope)
        expect(contractPoint.ts).to.equal(empty_point.ts)
        expect(contractPoint.blk).to.equal(empty_point.blk)

        await ve.set_point_history(epoch, point)

        contractPoint = await ve.point_history(epoch)
        expect(contractPoint.bias).to.equal(point.bias)
        expect(contractPoint.slope).to.equal(point.slope)
        expect(contractPoint.ts).to.equal(point.ts)
        expect(contractPoint.blk).to.equal(point.blk)

        contractPoint = await ve.user_point_history(user, user_epoch)
        expect(contractPoint.bias).to.equal(empty_point.bias)
        expect(contractPoint.slope).to.equal(empty_point.slope)
        expect(contractPoint.ts).to.equal(empty_point.ts)
        expect(contractPoint.blk).to.equal(empty_point.blk)

        await ve.set_user_point_history(user, user_epoch, user_point)

        contractPoint = await ve.user_point_history(user, user_epoch)
        expect(contractPoint.bias).to.equal(user_point.bias)
        expect(contractPoint.slope).to.equal(user_point.slope)
        expect(contractPoint.ts).to.equal(user_point.ts)
        expect(contractPoint.blk).to.equal(user_point.blk)
    })

    it("sendUserVeBalance(): sends cross chain properly", async function () {
        let epoch = 10
        let point = {
            bias: "95908345856757702214638",
            slope: "5305473300535549",
            ts: "1648652538",
            blk: "14488225"
        }
        let user_epoch = 5
        let user_point = {
            bias: "959083458567577022146",
            slope: "53054733005355",
            ts: "16486525",
            blk: "144882"
        }
        let empty_point= {
            bias: 0,
            slope: 0,
            ts: 0,
            blk: 0
        }

        // totalSupply
        await ve.set_epoch(epoch)
        await ve.set_point_history(epoch, point)

        // balanceOf(user)
        await ve.set_user_point_epoch(user, user_epoch)
        await ve.set_user_point_history(user, user_epoch, user_point)

        // ovec inits totalSupply to 0 point
        let totalSupply = await ovec.totalSupplyPoint()
        expect(totalSupply.bias).to.equal(empty_point.bias)
        expect(totalSupply.slope).to.equal(empty_point.slope)
        expect(totalSupply.ts).to.equal(empty_point.ts)
        expect(totalSupply.blk).to.equal(empty_point.blk)

        // ovec inits balanceOf to 0 point
        let balanceOf = await ovec.userPoints(user)
        expect(balanceOf.bias).to.equal(empty_point.bias)
        expect(balanceOf.slope).to.equal(empty_point.slope)
        expect(balanceOf.ts).to.equal(empty_point.ts)
        expect(balanceOf.blk).to.equal(empty_point.blk)

        let feeObj = await ove.estimateSendUserBalance(childChainId, false, "0x")

        await ove.sendUserBalance(user, childChainId, user, ethers.constants.AddressZero, "0x", {value: feeObj.nativeFee})

        totalSupply = await ovec.totalSupplyPoint()
        expect(totalSupply.bias).to.equal(point.bias)
        expect(totalSupply.slope).to.equal(point.slope)
        expect(totalSupply.ts).to.equal(point.ts)
        expect(totalSupply.blk).to.equal(point.blk)

        balanceOf = await ovec.userPoints(user)
        expect(balanceOf.bias).to.equal(user_point.bias)
        expect(balanceOf.slope).to.equal(user_point.slope)
        expect(balanceOf.ts).to.equal(user_point.ts)
        expect(balanceOf.blk).to.equal(user_point.blk)
    })

    it("sendTotalSupply(): sends cross chain properly", async function () {
        let epoch = 10
        let point = {
            bias: "95908345856757702214638",
            slope: "5305473300535549",
            ts: "1648652538",
            blk: "14488225"
        }
        let empty_point= {
            bias: 0,
            slope: 0,
            ts: 0,
            blk: 0
        }

        // totalSupply
        await ve.set_epoch(epoch)
        await ve.set_point_history(epoch, point)

        // ovec inits to 0 point
        let totalSupply = await ovec.totalSupplyPoint()
        expect(totalSupply.bias).to.equal(empty_point.bias)
        expect(totalSupply.slope).to.equal(empty_point.slope)
        expect(totalSupply.ts).to.equal(empty_point.ts)
        expect(totalSupply.blk).to.equal(empty_point.blk)

        let feeObj = await ove.estimateSendTotalSupply(childChainId, false, "0x")

        await ove.sendTotalSupply(childChainId, user, ethers.constants.AddressZero, "0x", {value: feeObj.nativeFee})

        totalSupply = await ovec.totalSupplyPoint()
        expect(totalSupply.bias).to.equal(point.bias)
        expect(totalSupply.slope).to.equal(point.slope)
        expect(totalSupply.ts).to.equal(point.ts)
        expect(totalSupply.blk).to.equal(point.blk)
    })

    // TODO
    it("getPointValue(): Deconstructs point properly", async function () {

    })
})
