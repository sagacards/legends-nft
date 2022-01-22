let upstream = https://github.com/aviate-labs/package-set/releases/download/v0.1.2/package-set.dhall sha256:770d9d2bd9752457319e8018fdcef2813073e76e0637b1f37a7f761e36e1dbc2

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  additions =
      [{ name = "cap"
      , repo = "https://github.com/Psychedelic/cap-motoko-library"
      , version = "v1.0.4"
      , dependencies = [] : List Text
      }] : List Package

in  upstream # additions