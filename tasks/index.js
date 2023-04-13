task("generateMnemonic", "", require("./generateMnemonic.js"))
task("verifyContract", "", require("./verifyContract.js")).addParam("contract", "contract name")