{ fetchFromGitHub }:
{
  # https://github.com/ayushnix/kangae (unmaintained)
  kangae = fetchFromGitHub {
    owner = "ayushnix";
    repo = "kangae";
    rev = "b265935373f1fe73e17b968204b13738dc6d4136"; # 2023-06-21
    hash = "sha256-ZFKvixwiM6RCP5/PPvv38r07vRLG76ny3gQwVN+QpC4=";
  };
  # https://github.com/Speyll/anemone
  anemone = fetchFromGitHub {
    owner = "Speyll";
    repo = "anemone";
    rev = "dbbaa6c3be90f16b998f1be11363ee15e35da374"; # 2025-04-10
    hash = "sha256-2IE5/wr0jcPGfk8jNogs/zsSpmD4XVUZx2x9dU1Sr8k=";
  };
}
