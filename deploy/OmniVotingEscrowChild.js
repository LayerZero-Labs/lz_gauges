const LZ_ENDPOINTS = require("../constants/layerzeroEndpoints.json")

module.exports = async function ({ deployments, getNamedAccounts }) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()
    console.log(`>>> your address: ${deployer}`)

    const lzEndpointAddress = LZ_ENDPOINTS[hre.network.name]
    console.log(`[${hre.network.name}] Endpoint Address: ${lzEndpointAddress}`)

    let delegationHook
    if (hre.network.name == "arbitrum") {
        delegationHook = "0x12Ca9De662A7Bf5Dc89e034a5083eF751B08EDe7"
    } else {
        throw `Invalid network: ${hre.network.name}`
    }


    await deploy("OmniVotingEscrowChild", {
        from: deployer,
        args: [lzEndpointAddress, delegationHook],
        log: true,
        waitConfirmations: 1,
    })
}

module.exports.tags = ["OmniVotingEscrowChild"]