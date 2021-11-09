let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.7-20210818/package-set.dhall
let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }

let additions = [{
    name = "base",
    repo = "https://github.com/dfinity/motoko-base",
    version = "dfx-0.7.2",
    dependencies = ["base"]
}, {
    name = "parser-combinators",
    repo = "https://github.com/aviate-labs/parser-combinators.mo",
    version = "v0.1.0",
    dependencies = ["base"]
  }, {
    name = "json",
    repo = "https://github.com/aviate-labs/json.mo",
    version = "main",
    dependencies = ["base", "parser-combinators"]
}] : List Package

in upstream # additions
