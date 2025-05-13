{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = [  ];
#  buildInputs = with pkgs; [ elixir portmidi supercollider];
  buildInputs = with pkgs; [ elixir portmidi supercollider alsa-lib rustc cargo pkg-config];
  LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.portmidi pkgs.pipewire.jack pkgs.alsa-lib];
}
