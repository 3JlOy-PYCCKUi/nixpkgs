import ./make-test-python.nix ({ pkgs, ... }:
let
  content = pkgs.writeTextDir "test/test.json"
    ''
      {
        "success": true
      }
    '';
  mkHost = address: { pkgs, ... }: {
    networking.enableIPv6 = true;
    services.darkhttpd = {
      enable = true;
      port = 8080;
      rootDir = "${content}/test";
      inherit address;
    };
    environment.systemPackages = [ pkgs.jq ];
  };
in
{
  name = "darkhttpd";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ ];
  };

  nodes = {
    v4 = mkHost "127.0.0.1";
    v6 = mkHost "::1";
  };

  testScript = ''
    start_all()

    v4.wait_for_unit("darkhttpd")
    v4.wait_for_open_port(8080)
    v4.succeed("curl --fail -4 http://127.0.0.1:8080/test.json | jq -e .success")

    v6.wait_for_unit("darkhttpd")
    v6.wait_for_open_port(8080)
    v6.succeed("curl --fail -6 http://[::1]:8080/test.json | jq -e .success")
  '';
})
