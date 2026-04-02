{
  description = "Secure Bubblewrap Sandbox for OpenCode CLI Forensics";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # Pull the opencode package directly from the upstream dev branch
    opencode-cli = {
      url = "github:anomalyco/opencode/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, opencode-cli }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    opencodePkg = opencode-cli.packages.${system}.opencode;
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [ 
        pkgs.bubblewrap 
        pkgs.tmux 
        opencodePkg 
      ];

      shellHook = ''
        echo "🛡️  Initializing Secure OpenCode Forensic Sandbox..."
        
        # Create an ephemeral home directory to capture anomalous writes
        export EPHEMERAL_HOME=$(mktemp -d)
        
        # Create a workspace that is mounted read-write
        export WORKSPACE=$(pwd)/agent_workspace
        mkdir -p $WORKSPACE

        # Alias the opencode CLI to run inside bubblewrap
        alias opencode-secure='bwrap \
          --ro-bind /usr /usr \
          --ro-bind /bin /bin \
          --ro-bind /lib /lib \
          --ro-bind /lib64 /lib64 \
          --ro-bind /nix/store /nix/store \
          --ro-bind /etc/resolv.conf /etc/resolv.conf \
          --dev /dev \
          --proc /proc \
          --bind $EPHEMERAL_HOME /home/shift \
          --bind $WORKSPACE /workspace \
          --chdir /workspace \
          --setenv HOME /home/shift \
          --unshare-all \
          --share-net \
          opencode'
          
        echo "✅ Sandbox ready. Run 'opencode-secure' to start the agent."
        echo "   - Upstream OpenCode CLI loaded from Nix Flake."
        echo "   - The agent's ~ is mapped to: $EPHEMERAL_HOME"
        echo "   - Allows safe approval of anomalous path writes during observation."
      '';
    };
  };
}
