{ fetchFromGitHub }:
{
  kangae = fetchFromGitHub {
    owner = "ayushnix";
    repo = "kangae";
    rev = "b265935373f1fe73e17b968204b13738dc6d4136";
    hash = "sha256-ZFKvixwiM6RCP5/PPvv38r07vRLG76ny3gQwVN+QpC4=";
  };
  anemone = fetchFromGitHub {
    owner = "Speyll";
    repo = "anemone";
    rev = "ae125d2bc6297160b46bae3d230715b67c0705e9";
    hash = "sha256-EmWijjmrbsW93awqfkbMT7XIvoXokENnNfGfBLuDy1I=";
  };
}
