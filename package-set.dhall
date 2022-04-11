let upstream = https://github.com/aviate-labs/package-set/releases/download/v0.1.5/package-set.dhall sha256:8cfc64fd3c6e8aa93390819b5f96dfb064afb63817971bcc8d9aa00c312ec8ab

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
      [{ name = "cap"
      , repo = "https://github.com/Psychedelic/cap-motoko-library"
      , version = "v1.0.4"
      , dependencies = [] : List Text
      }, { name = "canistergeek"
      , repo = "https://github.com/jorgenbuilder/canistergeek-ic-motoko"
      , version = "master"
      , dependencies = [] : List Text
      }] : List Package

in  upstream # additions