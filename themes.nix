{ fetchFromGitHub }:
{
  # https://github.com/ayushnix/kangae (unmaintained)
  kangae = fetchFromGitHub {
    owner = "ayushnix";
    repo = "kangae";
    rev = "b265935373f1fe73e17b968204b13738dc6d4136"; # 2023-06-21
    hash = "sha256-ZFKvixwiM6RCP5/PPvv38r07vRLG76ny3gQwVN+QpC4=";
  };
  # https://github.com/Speyll/anemone (not compatible with Tera v2)
  anemone = fetchFromGitHub {
    owner = "Speyll";
    repo = "anemone";
    rev = "47b2085cb01f0e82fd83221aad79ab0b3d1702e0"; # 2025-04-10
    hash = "sha256-vyB7gLKzTFLSEPPD4ylc3Uyj3WeKRFFklEnE58jn5JA=";
  };
  linkita = fetchFromGitHub {
    owner = "salif";
    repo = "linkita";
    rev = "6cd781f40bc93dbacb8d7f3fa5aea21c4b40d311"; # 2026-09-07
    hash = "sha256-PPi3VHJpkjIyW1x0GEiodDCvs1UBLWi1UgP4Mm8tiJk=";
  };
}
