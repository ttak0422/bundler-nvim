{ pkgs }:
{
  bundler-nvim = {
    package = pkgs.vimUtils.buildVimPlugin {
      pname = "bundler-nvim";
      version = "2.2.1";
      src = ./../bundler-nvim;
    };
  };
}
