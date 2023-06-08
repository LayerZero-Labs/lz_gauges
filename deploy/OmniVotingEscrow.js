const LZ_ENDPOINTS = require("../constants/layerzeroEndpoints.json")
const verify = require('@layerzerolabs/verify-contract')

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    // console.log(`>>> your address: ${deployer}`)
    //
    // const lzEndpointAddress = LZ_ENDPOINTS[hre.network.name]
    // console.log(`[${hre.network.name}] Endpoint Address: ${lzEndpointAddress}`)
    //
    // let votingEscrowRemapper
    //
    // if (hre.network.name == "ethereum") {
    //     votingEscrowRemapper = "0x83E443EF4f9963C77bd860f94500075556668cb8"
    // } else if (hre.network.name == "hardhat") {
    //     votingEscrowRemapper = await deployments.get("VotingEscrowMock")
    // } else {
    //     throw `Cant deploy OmniVotingEscrow.sol on ${hre.network.name}`
    // }
    //
    // await deploy("OmniVotingEscrow", {
    //     from: deployer,
    //     args: [lzEndpointAddress, votingEscrowRemapper],
    //     log: true,
    //     waitConfirmations: 1,
    // })
    //
    // await verify(hre.network.name, "OmniVotingEscrow")


    const MULTI_SIGS = {
        "ethereum": "0xc38c5f97B34E175FFd35407fc91a937300E33860"
    }

    const newOwner = MULTI_SIGS[hre.network.name]
    console.log("NewOwner: ", newOwner)

    let accounts = await ethers.getSigners()
    let owner = accounts[0]

    let omniVotingEscrow = await ethers.getContract("OmniVotingEscrow")
    await omniVotingEscrow.connect(owner).transferOwnership(newOwner)
}

module.exports.tags = ["OmniVotingEscrow"]
