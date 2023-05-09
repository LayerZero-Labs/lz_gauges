const LZ_ENDPOINTS = require("../constants/layerzeroEndpoints.json")
const verify = require('@layerzerolabs/verify-contract')

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    const lzEndpointAddress = LZ_ENDPOINTS[hre.network.name]
    console.log(`[${hre.network.name}] Endpoint Address: ${lzEndpointAddress}`)

    let votingEscrowRemapper

    if (hre.network.name == "ethereum") {
        votingEscrowRemapper = "0x6B5dA774890Db7B7b96C6f44e6a4b0F657399E2e"
        // } else if (hre.network.name == "goerli") {
        //     votingEscrowRemapper = "0x33A99Dcc4C85C014cf12626959111D5898bbCAbF"
    } else if (hre.network.name == "hardhat") {
        votingEscrowRemapper = await deployments.get("VotingEscrowMock")
    } else {
        throw `Cant deploy OmniVotingEscrow.sol on ${hre.network.name}`
    }

    await deploy("OmniVotingEscrow", {
        from: deployer,
        args: [lzEndpointAddress, votingEscrowRemapper],
        log: true,
        waitConfirmations: 1,
    })

    await verify(hre.network.name, "OmniVotingEscrow")
}

module.exports.tags = ["OmniVotingEscrow"]
// module.exports.dependencies = ["VotingEscrowMock"]
